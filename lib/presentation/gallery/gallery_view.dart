import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_scene/scene.dart';
import 'package:portfolio/data/di/dependency_manager.dart';
import 'package:portfolio/domain/audio/app_audio.dart';
import 'package:portfolio/domain/gallery/control_layout.dart';
import 'package:portfolio/domain/gallery/gallery_camera_path.dart';
import 'package:portfolio/domain/config/logo_config.dart';
import 'package:portfolio/domain/gallery/gallery_dimensions.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';
import 'package:portfolio/domain/gallery/keyboard_orbit.dart';
import 'package:portfolio/domain/gallery/project_focus.dart';
import 'package:portfolio/domain/gallery/skill_data.dart';
import 'package:portfolio/domain/gallery/walk_order.dart';
import 'package:portfolio/domain/radio/radio_player.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/domain/style/text_styles.dart';
import 'package:portfolio/domain/utils/crossing.dart';
import 'package:portfolio/domain/utils/scroll_driver.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/gallery/frame_picker.dart';
import 'package:portfolio/presentation/gallery/gallery_mark.dart';
import 'package:portfolio/presentation/gallery/gallery_overlay.dart';
import 'package:portfolio/presentation/gallery/gallery_scene_builder.dart';
import 'package:portfolio/presentation/gallery/scene_axes.dart';
import 'package:portfolio/presentation/gallery/scroll_gate.dart';
import 'package:vector_math/vector_math.dart';

/// The gallery: a corridor of work the visitor walks through.
///
/// Stateful, and this is one of the cases that genuinely requires it. The
/// scene is built asynchronously, it owns GPU resources that must be released
/// on the way out, and the scroll position has to survive rebuilds.
class GalleryView extends StatefulWidget {
  const GalleryView({super.key});

  /// Which way a wheel turn walks the corridor.
  ///
  /// Inverted with respect to the stages before it, and deliberately so. Up
  /// to here the scroll has been moving a *page*: content travels up as the
  /// wheel goes down, which is what every scrolling surface does. The gallery
  /// is not a page — the visitor is walking through a room, and the natural
  /// reading of pushing the wheel away is moving away, deeper in.
  ///
  /// Keeping the page convention here would mean pushing forward to back out
  /// of the corridor, which fights the first-person framing the whole scene
  /// is built on.
  /// How far a finger walks the corridor, against how far it travels.
  ///
  /// A wheel notch reports about a hundred units and a finger reports the
  /// pixels it crossed, so one-to-one makes the corridor several times
  /// longer to a thumb than to a mouse. Matched to the intro's own gain, so
  /// the two stages answer a swipe at the same rate.
  static const double dragScrollGain = 2;

  static const double scrollDirection = -1;

  /// Identifies the stand-in shown while the corridor is still building.
  static const Key placeholderKey = ValueKey('gallery-placeholder');

  /// How far the visitor scrolls to walk the whole gallery.
  ///
  /// Long: the corridor is the substance of the site and hurrying it defeats
  /// the point. Divided into a walk, a wall pan and the approach to the hall
  /// by [GalleryCameraPath].
  ///
  /// Grown from 6000 when the hall was added, rather than the hall being
  /// carved out of what was there. The corridor and the pan keep exactly the
  /// scroll distance they had — everything already tuned against them still
  /// feels the same, and only the new stretch is new.
  static const double scrollExtent = 8000;

  /// Where the walk ends and the far wall is square on.
  ///
  /// Derived from the camera path rather than dialled in, so retiming the
  /// walk moves the pause with it. A pause at a position the camera no
  /// longer stops at is worse than none: it holds the visitor in the middle
  /// of a turn.
  static double get backWallStop =>
      GalleryCameraPath.walkFraction * scrollExtent;

  /// How long the corridor takes to go dark on the way out.
  ///
  /// Short. This is the visitor being taken somewhere, not a scene change
  /// being admired — long enough that the room is seen to go rather than to
  /// vanish, and no longer.
  static const Duration leaving = Duration(milliseconds: 380);

  /// How long it takes when the mark is flying home at the same time.
  ///
  /// Longer, because there is something to watch. The mark crosses most of
  /// the screen and grows fivefold on the way, and at the pace the room goes
  /// dark that reads as a jump rather than as a journey.
  static const Duration leavingWithMark = LogoConfig.contactTravel;

  @override
  State<GalleryView> createState() => _GalleryViewState();
}

class _GalleryViewState extends State<GalleryView> {
  GalleryScene? _gallery;
  Object? _error;

  /// The same driver the bold-text stage uses, so the gallery inherits its
  /// weight and its resistance to a flick teleporting the view.
  late final ScrollDriver _scroll = ScrollDriver(
    extent: GalleryView.scrollExtent,
    progressExtent: GalleryView.scrollExtent,
    // One pause, at the far wall. The corridor is otherwise a continuous
    // walk and halting it at fixed frames would fight the scroll — but the
    // end of the walk is the one place there is something to *read*, and a
    // statement the visitor coasts past at scrolling speed may as well not
    // be on the wall. The detent only claims a scroll that has already
    // slowed to an ordinary pace (see `ScrollMotion`), so it catches someone
    // walking down the corridor and lets a deliberate fling through.
    snapPoints: <double>[GalleryView.backWallStop],
  );

  /// Keeps the gesture that ended the previous stage from driving this one.
  ///
  /// A fixed delay was not enough: a long, deliberate scroll outlasts any
  /// timeout and leaks through it. The gate waits for the input to go quiet
  /// instead, which is what actually separates one gesture from the next.
  final ScrollGate _gate = ScrollGate();

  /// How far the lights have gone down on the way out, `0`..`1`.
  ///
  /// A notifier rather than a field behind `setState`. It is written from
  /// the render loop, and rebuilding the whole corridor — the scene view,
  /// the gate, the overlay — sixty times a second to darken one rectangle is
  /// the exact cost this view already goes out of its way to avoid for the
  /// camera. Only the rectangle listens.
  final ValueNotifier<double> _leaving = ValueNotifier<double>(0);

  /// The moment the board begins to rise at the end of the hall.
  ///
  /// Taken from the same curve the board's own reveal is taken from, so the
  /// sound cannot start before the movement does however that curve is
  /// retuned.
  /// Whether the far wall had hold of the scroll on the previous frame.
  bool _wasSnapping = false;

  /// How far the header mark has flown back toward the middle.
  ///
  /// `1` parked in the corner, `0` at home. Only the contact screen pulls it
  /// home — leaving for the title parks it there anyway, so animating it
  /// would be moving something to where it already is.
  final ValueNotifier<double> _markJourney = ValueNotifier<double>(1);

  /// Follows the radio so the face on the wall says what it is doing.
  StreamSubscription<RadioState>? _radio;

  final Crossing _boardRising = Crossing(
    at: GalleryCameraPath.revealBegins,
    rearmAt: GalleryCameraPath.revealBegins - 0.02,
  );

  /// What to raise once the lights are out, or null while the visitor is
  /// still in the room.
  ///
  /// The corridor and the logo screen are different renderers, so there is
  /// no frame in which both are drawing and no way to dissolve one into the
  /// other. Going out through black is what makes the handover a transition
  /// instead of a cut — and holding the event until the black is down is
  /// what stops the scene changing underneath a room the visitor can still
  /// see.
  SceneEvent? _leavingFor;

  /// The order the visitor steps through the work in — by depth down the
  /// corridor, both walls interleaved. See [FocusOrder].
  late final List<Placement> _pickable = GalleryLayout.build();
  late final WalkOrder _order = WalkOrder(_pickable);

  /// The piece being read, or null while walking the corridor.
  Placement? _focused;

  /// The key the visitor last pressed on the skills board.
  Skill? _skill;

  /// How the visitor has turned the board.
  late final KeyboardOrbit _orbit = KeyboardOrbit(
    restElevation: GalleryCameraPath.hallRestElevation,
  );

  /// Where the drag started, and how far it has run.
  ///
  /// A drag and a press arrive as the same pair of events; only the distance
  /// between them tells the two apart. Without this, turning the board would
  /// also press whichever key the gesture happened to finish on.
  Offset? _dragFrom;
  double _dragDistance = 0;

  /// How far the pointer may travel and still count as a press.
  static const double _tapSlop = 6;

  /// Where the camera actually is, as opposed to where it is wanted.
  ///
  /// Focusing is a move, not a cut: the shot has to travel so the visitor
  /// keeps their bearings and knows the room did not change around them.
  Vector3? _eye;
  Vector3? _look;

  /// The last camera built, kept so a tap can be projected back into the
  /// scene. Picking needs the exact transform the visitor clicked on, and
  /// rebuilding one from the scroll position would answer for a different
  /// frame than the one on screen.
  PerspectiveCamera? _lastCamera;
  Size _viewSize = Size.zero;

  /// Clock the gate reasons in. Started with the view, so a gesture already
  /// in flight is measured from the moment the corridor appeared.
  final Stopwatch _clock = Stopwatch()..start();

  @override
  void initState() {
    super.initState();

    // Taken synchronously when the loading screen already built it, which is
    // the normal case. Awaiting even a completed future costs a frame, and
    // that frame shows a flat placeholder between the stage that just ended
    // and the corridor — a seam in what should be one continuous move.
    _gate.arrive(_clock.elapsedMilliseconds);

    _gallery = GalleryScene.ready;
    if (_gallery == null) _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Where the radio is picked up, and deliberately not in `_load`.
    //
    // `_load` runs only when the scene was *not* warmed during the intro —
    // the uncommon case, because warming it is the whole point of the
    // loading screen. Subscribing there meant that on every ordinary visit
    // nothing ever listened to the radio, and the faces kept whatever they
    // were baked with: PLAY over a radio that was playing, OFF over one on
    // air, and a station name that did not follow the dial.
    //
    // Here because this runs on both paths and cannot be skipped by either,
    // and because it is the earliest point a theme may be read — `initState`
    // is too early for that, which is what pushed the call into `_load` to
    // begin with.
    final gallery = _gallery;
    if (gallery == null || _radio != null) return;
    _tuneIn(gallery);
  }

  /// Builds the corridor, for the case it was not warmed during the intro.
  ///
  /// Guarded by a zone rather than a `try`. Bringing up the scene starts GPU
  /// work of its own, and when that fails — no backend, a headless harness —
  /// the error surfaces from inside the engine's async machinery rather than
  /// on the future awaited here. A `catch` around the await never sees it, and
  /// what should have been this view's failure screen becomes an unhandled
  /// error that takes the app down with it.
  void _load() {
    runZonedGuarded(
      () async {
        final gallery = await GalleryScene.warmUp();
        if (!mounted) {
          // Disposed while the build was in flight; nothing will ever show it,
          // so release it here rather than leaking a whole scene.
          gallery.dispose();
          return;
        }
        setState(() => _gallery = gallery);

        // `didChangeDependencies` has already run for this element with no
        // scene to hand it, so the subscription is made here instead.
        // `_tuneIn` replaces rather than adds, so the two cannot stack.
        _tuneIn(gallery);
      },
      (error, stack) {
        if (mounted) setState(() => _error = error);
      },
    );
  }

  /// How fast the camera settles, in units of "fraction closed per second".
  ///
  /// Faster into focus than out of it. Arriving should feel decisive; leaving
  /// should hand the corridor back gently, because the visitor is being
  /// returned to a position they did not choose.
  static const double focusApproach = 7;
  static const double corridorReturn = 4.5;

  void _focus(Placement? frame) {
    if (frame?.project?.id == _focused?.project?.id) return;

    setState(() => _focused = frame);
    _placeControls(frame);
  }

  /// Brings the room's own controls to [frame], or takes them away.
  ///
  /// Called from [_focus] unconditionally, and the reason is worth stating:
  /// the controls are hidden the moment they are built, and nothing but
  /// [ControlIcons.showFor] ever reveals them. A focus that skips this leaves
  /// three icons loaded, parented, lit and permanently invisible — and
  /// because they *did* load, the plain fallback row stays suppressed, so the
  /// visitor is left with no controls at all rather than simpler ones.
  void _placeControls(Placement? frame) {
    final controls = _gallery?.controls;
    if (controls == null) return;

    if (frame == null) {
      controls.hide();
      return;
    }

    controls.showFor(
      frame,
      canGoBack: _order.hasPrevious(frame),
      canGoForward: _order.hasNext(frame),
    );
  }

  void _step(Placement? Function(Placement) move) {
    final current = _focused;
    if (current == null) return;

    final next = move(current);
    if (next != null) _focus(next);
  }

  /// Takes the lights down, then raises [event].
  ///
  /// Ignores a second request: the visitor pressing the sign twice while the
  /// room is going dark should not restart the fade or queue two events.
  void _leave(SceneEvent event) {
    if (_leavingFor != null) return;
    setState(() => _leavingFor = event);
  }

  /// Acts on one of the three controls, whichever way it was pressed.
  ///
  /// The 3D icons on the wall and the 2D fallback both come through here, so
  /// they cannot drift — and neither can what they sound like. These three
  /// keep their own voices where every other press shares one: direction is
  /// the whole meaning of stepping back, stepping on and closing, and a
  /// single click throws it away.
  void _control(ControlAction action) {
    switch (action) {
      case ControlAction.previous:
        _sound(AudioCue.previous);
        _step(_order.previous);
      case ControlAction.next:
        _sound(AudioCue.next);
        _step(_order.next);
      case ControlAction.exit:
        _sound(AudioCue.close);
        _focus(null);
    }
  }

  /// Plays a cue, if this view still has a context to find one through.
  ///
  /// Called from the render loop as well as from taps — see the arrow and
  /// the board below — and a tick can outlive the widget.
  void _sound(AudioCue cue) {
    if (!mounted) return;
    context.audio.play(cue);
  }

  void _pick(Offset at) {
    final camera = _lastCamera;
    final gallery = _gallery;
    if (camera == null || gallery == null || _viewSize.isEmpty) return;

    final hit = FramePicker.at(
      at,
      _viewSize,
      _pickable,
      camera.position,
      (world) => camera.worldToScreen(world, _viewSize),
      kinds: <SurfaceKind>{
        SurfaceKind.frame,
        SurfaceKind.exitSign,
        SurfaceKind.radioPlay,
        SurfaceKind.radioNext,
        // Only once they are standing in the hall. Every sign in the room
        // projects to somewhere on screen whether or not there is a wall in
        // front of it, and an invitation that can be pressed through the
        // back of the corridor would take the visitor out of a gallery they
        // had not finished walking.
        if (_inHall) SurfaceKind.connectSign,
      },
    );

    // The board is only reachable once the visitor has arrived at it, and
    // only then is it still enough to aim at.
    if (_inHall) {
      final caps = gallery.keyboard.keycaps();
      final hit = FramePicker.at(
        at,
        _viewSize,
        caps,
        camera.position,
        (world) => camera.worldToScreen(world, _viewSize),
        kinds: const <SurfaceKind>{SurfaceKind.keycap},
      );

      if (hit != null) {
        _sound(AudioCue.keyStroke);
        final skill = gallery.keyboard.skillAt(hit);
        // Pressing the key already up releases it, so the board is never
        // stuck showing a choice the visitor has moved on from.
        final next = skill?.id == _skill?.id ? null : skill;
        gallery.keyboard.select(next);
        setState(() => _skill = next);
        return;
      }
    }

    // The controls sit in front of the work, so they are offered the tap
    // first — otherwise pressing one would also pick the piece behind it.
    final control = _controlAt(at, camera);
    if (control != null) {
      _control(control);
      return;
    }

    if (hit?.kind == SurfaceKind.radioPlay) {
      _sound(AudioCue.click);
      final radio = locate<RadioPlayer>();

      // Not awaited, and said so. Opening a stream takes seconds; a tap
      // handler that waited on it would hold the corridor still while the
      // radio dialled out.
      unawaited(
        radio.state.isPlaying || radio.state.isTuning
            ? radio.stop()
            : radio.play(),
      );
      return;
    }

    if (hit?.kind == SurfaceKind.radioNext) {
      _sound(AudioCue.click);
      unawaited(locate<RadioPlayer>().next());
      return;
    }

    if (hit?.kind == SurfaceKind.exitSign) {
      _sound(AudioCue.pageTurn);
      _leave(const SceneEvent.galleryExited());
      return;
    }

    if (hit?.kind == SurfaceKind.connectSign) {
      _sound(AudioCue.pageTurn);
      _leave(const SceneEvent.contactRequested());
      return;
    }

    // A tap on the plaster is not a request to leave. Exiting is the ✕, and
    // dismissing on any miss would make the room feel like it was trying to
    // get rid of you.
    if (hit == null) return;
    _sound(AudioCue.click);
    _focus(hit);
  }

  /// Whether the visitor has arrived at the board, close enough that the
  /// orbit may take the camera over from the path.
  ///
  /// Asked of the scroll, and it has to be: asking the *camera* whether it
  /// had reached the stop created a loop that made orbiting impossible.
  /// Walking round the board moves the camera away from the stop, which
  /// ended the orbit, which handed the camera back to the path, which pulled
  /// it to the stop, which started the orbit again — the board and the room
  /// each yanking the view back a frame at a time, and neither turning.
  ///
  /// The scroll has no such feedback: it says where the visitor asked to be,
  /// not where the camera happens to have got to. It never quite reaches one
  /// — see `ScrollDriver` — so this asks for very nearly the end rather than
  /// the end itself.
  bool get _atBoard =>
      _scroll.progress >
      GalleryCameraPath.panEnd + GalleryCameraPath.hallFraction * 0.98;

  /// Whether the visitor is actually standing in the skills hall.
  ///
  /// Asked of the camera, not of the scroll, and that distinction is the
  /// whole of a bug that made the keyboard completely inert. The obvious
  /// test — "the approach has finished", `_hallArrival >= 1` — requires the
  /// scroll's progress to reach exactly one, and it never does: the driver
  /// chases its target with an exponential spring, so it closes on the end
  /// asymptotically and settles at 0.9999999999999996. Every gate behind
  /// that condition was unreachable, so neither turning the board nor
  /// pressing a key ever became possible.
  ///
  /// Where the camera has got to is the thing actually being asked about,
  /// and it answers plainly: past the doorway, the visitor is in the room.
  bool get _inHall {
    final eye = _eye;
    return eye != null && eye.x > GalleryDimensions.kbEntryX;
  }

  /// Which control is under [at], if any.
  ControlAction? _controlAt(Offset at, PerspectiveCamera camera) {
    final controls = _gallery?.controls;
    if (controls == null) return null;

    final row = controls.placements;
    if (row.isEmpty) return null;

    // Reuses the frames' picker by describing each control as a flat quad on
    // the same wall, which is exactly what it is.
    final hit = FramePicker.at(
      at,
      _viewSize,
      row
          .map(
            (p) => Placement(
              kind: SurfaceKind.exitSign,
              position: p.position,
              extents: p.extents,
            ),
          )
          .toList(),
      camera.position,
      (world) => camera.worldToScreen(world, _viewSize),
      kinds: const <SurfaceKind>{SurfaceKind.exitSign},
    );
    if (hit == null) return null;

    return row.firstWhere((p) => p.position == hit.position).action;
  }

  /// Runs the lights down and raises the held event when they are out.
  void _advanceLeaving(double dt) {
    final event = _leavingFor;
    if (event == null || _leaving.value >= 1) return;

    final journeying = event is ContactRequested;
    final duration = journeying
        ? GalleryView.leavingWithMark
        : GalleryView.leaving;

    final step = dt / (duration.inMilliseconds / 1000);
    final next = (_leaving.value + step).clamp(0.0, 1.0);
    _leaving.value = next;

    // Eased at both ends, the way the mark's own retreat is, so it leaves
    // the corner and arrives in the middle without a corner in the motion.
    if (journeying) {
      _markJourney.value = 1 - Curves.easeInOutCubic.transform(next);
    }

    if (next < 1) return;

    // Raised from the render loop, so it cannot go out during a build.
    // `queue` is the bloc's own inbox and defers to the next turn.
    if (mounted) context.read<SceneBloc>().queue(event: event);
  }

  /// Keeps every radio face in step with the radio.
  ///
  /// Listening only. Whether the radio *plays* is the scene bloc's to decide
  /// — it is the one thing that knows which screen the visitor is on — and
  /// this used to start it too, which is how a stream came to go on playing
  /// under the contact screen.
  ///
  /// One subscription re-letters both faces: `WallRadios.show` writes every
  /// panel it holds, so the corridor's radio and the hall's cannot disagree
  /// about what is on air. They are one radio with two faces, not two.
  void _tuneIn(GalleryScene gallery) {
    // Replaced rather than added to. The scene can report ready more than
    // once, and a second listener here would re-letter every face twice per
    // change while the first went on running against a stale scene.
    _radio?.cancel();

    // Told what the radio is doing now as well as what it does next —
    // `RadioPlayer.changes` opens with the current state, which is what
    // makes subscribing late safe. This arrives very late indeed: the scene
    // has to finish warming up first.
    _radio = locate<RadioPlayer>().changes.listen((state) async {
      if (!mounted) return;

      // Read from the theme on each change rather than captured once. Every
      // other letter in this room comes from the design system, and a face
      // reaching for its own `DefaultAppTypography` is the one surface that
      // stops following it.
      await gallery.radio.show(state: state, type: context.typography);
    });
  }

  @override
  void dispose() {
    _radio?.cancel();
    _leaving.dispose();
    _markJourney.dispose();
    // The scene is deliberately *not* disposed here. It is memoised so it is
    // built once, and this widget is only the window onto it — tearing it
    // down every time the visitor steps out threw away seconds of decoding
    // and uploading, and made walking back in a rebuild rather than a return.
    // `GalleryScene.dispose` remains for a genuine teardown; nothing in the
    // ordinary flow is one.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The gate is fed from out here, wrapping every branch without exception. Mount it only
    // around the finished scene and it is blind for as long as the scene
    // takes to arrive: the tail of the previous gesture flows past unseen,
    // the activity clock stays frozen at the handover, and the first event
    // the gate actually sees reads as the pause it was waiting for. It then
    // arms mid-gesture, which is precisely the leak it exists to prevent.
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewSize = constraints.biggest;

        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // The gate wraps every branch without exception. Mount it only
            // around the finished scene and it is blind for as long as the
            // scene takes to arrive: the tail of the previous gesture flows
            // past unseen, the activity clock stays frozen at the handover,
            // and the first event the gate actually sees reads as the pause
            // it was waiting for. It then arms mid-gesture, which is
            // precisely the leak it exists to prevent.
            Listener(
              onPointerSignal: (event) {
                if (event is! PointerScrollEvent) return;
                // Every event is offered to the gate, including the ones it
                // swallows — a continuous stream must not look like a pause
                // simply because none of it was acted on.
                if (!_gate.accept(_clock.elapsedMilliseconds)) return;
                // The driver clamps to `[0, extent]`, so scrolling the wrong
                // way at the entrance simply holds there rather than running
                // off the start.
                _scroll.scrollBy(
                  event.scrollDelta.dy * GalleryView.scrollDirection,
                );
              },
              // Without this the placeholder is not a hit-test target, and
              // the events it is here to swallow go straight past it.
              behavior: HitTestBehavior.opaque,
              onPointerDown: (event) {
                _dragFrom = event.localPosition;
                _dragDistance = 0;
              },
              onPointerMove: (event) {
                final from = _dragFrom;
                if (from == null) return;
                _dragDistance += event.delta.distance;

                // Only the board turns by dragging. Everywhere else a drag
                // *is* the scroll — on a phone, where there is no wheel, it
                // is the only way down the corridor at all.
                if (_inHall) {
                  _orbit.drag(event.delta.dx, event.delta.dy);
                  return;
                }

                // Touch and stylus only. A mouse has a wheel, and making a
                // held button drag the corridor as well would fight picking
                // a frame: every slightly unsteady click would walk the
                // camera before landing.
                if (event.kind != PointerDeviceKind.touch &&
                    event.kind != PointerDeviceKind.stylus) {
                  return;
                }

                // Through the same gate as the wheel, so being caught at the
                // back wall feels the same whichever way the visitor moves.
                if (!_gate.accept(_clock.elapsedMilliseconds)) return;

                // A finger moving up walks forward: the room follows the
                // hand rather than opposing it.
                _scroll.scrollBy(
                  -event.delta.dy *
                      GalleryView.dragScrollGain *
                      GalleryView.scrollDirection,
                );
              },
              onPointerUp: (event) {
                final dragged = _dragDistance > _tapSlop;
                _dragFrom = null;
                if (dragged) return;
                _pick(event.localPosition);
              },
              onPointerCancel: (_) => _dragFrom = null,
              child: _surface(context),
            ),

            // A sibling above the gate, not a child of it. Nested, every tap
            // on a control also reached the listener's `onPointerUp` —
            // ancestors receive every event in the hit path — so pressing ›
            // stepped to the next piece and was immediately overruled by a
            // pick of whatever was still under the pointer. That is why the
            // arrows did nothing.
            GalleryOverlay(
              focused: _focused,
              canGoBack: _focused != null && _order.hasPrevious(_focused!),
              canGoForward: _focused != null && _order.hasNext(_focused!),
              // Through the same dispatch as the icons on the wall, so the
              // fallback cannot do anything the real controls do not — or
              // sound different doing it.
              onBack: () => _control(ControlAction.previous),
              onExit: () => _control(ControlAction.exit),
              onForward: () => _control(ControlAction.next),
              mirrored: !(_focused?.position.x.isNegative ?? true),
              asFallback: _gallery?.controls == null,
            ),

            // Over the room *and* over its controls. A ✕ still lit on a
            // corridor that has gone dark reads as the page having failed
            // rather than as a door closing.
            // Boundaried, like the mark. A full-screen wash whose colour
            // changes every frame repaints whatever shares its layer, and
            // what shares this one is a 3D scene being composited — so the
            // fade was costing a re-composite of the whole corridor sixty
            // times a second on its way out.
            RepaintBoundary(
              child: ValueListenableBuilder<double>(
                valueListenable: _leaving,
                builder: (context, leaving, _) => leaving <= 0
                    ? const SizedBox.shrink()
                    : AbsorbPointer(
                        // Absorbing, not passing through: once the lights are
                        // going down the room stops answering. `IgnorePointer`
                        // is the wrong tool however it is configured — off, it
                        // is a no-op, and a `ColoredBox` does not hit-test
                        // itself, so every click and scroll went straight
                        // through to the room behind.
                        child: ColoredBox(
                          color: context.colors.sceneVeil.withValues(
                            alpha: leaving,
                          ),
                        ),
                      ),
              ),
            ),

            // The header mark, above everything the room draws and above
            // the dark it goes out through. It is the one thing that
            // survives the handover between the two renderers, so covering
            // it with the fade would defeat the point of drawing it here.
            // No boundary out here: the mark returns a `Positioned`, and a
            // render object between it and the `Stack` leaves it with no
            // stack to give its parent data to. It carries its own boundary
            // inside, where it belongs.
            ValueListenableBuilder<double>(
              valueListenable: _markJourney,
              builder: (context, journey, _) => GalleryMark(journey: journey),
            ),
          ],
        );
      },
    );
  }

  Widget _surface(BuildContext context) {
    final error = _error;
    if (error != null) return GalleryFailure(error: error);

    final gallery = _gallery;
    if (gallery == null) return const GalleryPlaceholder();

    return SceneView(
      gallery.scene,
      // Driven from the render loop rather than from setState. Rebuilding
      // this subtree every frame to move a camera re-runs the whole widget
      // tree sixty times a second for a value the renderer could read
      // directly — which is what made arriving here stutter.
      onTick: (elapsed, deltaSeconds) {
        // The scroll keeps running while a piece is focused, but it drives
        // nothing — so leaving focus hands the visitor back to exactly the
        // spot they left rather than to wherever the wheel wandered.
        if (_focused == null) _scroll.update(deltaSeconds);
        final seconds = elapsed.inMicroseconds / 1e6;
        gallery.arrow?.update(seconds, _scroll.progress);

        // Until the visitor has arrived the board turns gently on its own;
        // after that it is theirs to turn, and carries their flick on.
        // The board rises into view before the visitor sets off to meet it,
        // and stays put thereafter — it is the camera that moves around it.
        // No warm-up frame here any more. It was meant to compile the
        // board's shaders early by drawing it once, and it could not: the
        // board is thirty units away behind two walls at that point, so
        // there is every chance it is culled and nothing is submitted at
        // all. The board now uses the same plain material as the corridor,
        // so there is no shader left that needs warming.
        gallery.keyboard.reveal(
          GalleryCameraPath.revealAt(_scroll.progress),
          elapsed: seconds,
          // The board's heading is damped rather than mapped, so it needs to
          // know how long the frame was.
          dt: deltaSeconds,
        );

        if (!_atBoard) {
          // Leaving. Eased back to the doorway view so a reverse scroll walks
          // the visitor out facing the way they came, rather than sideways
          // from wherever they had wandered round to.
          _orbit.settle(deltaSeconds);
        } else if (_dragFrom == null) {
          _orbit.update(deltaSeconds);
        }
        _advanceCamera(deltaSeconds);
        _advanceLeaving(deltaSeconds);

        // Hung off the scroll rather than off a tap, so both have to be
        // watched for a crossing — the position is reported every frame, and
        // comparing it to a mark in here would play the cue sixty times a
        // second. See [Crossing].
        if (_boardRising.crossed(_scroll.progress)) {
          _sound(AudioCue.keyboardEntry);
        }

        // The far wall taking hold. Watched as an edge rather than as a
        // position: the driver stays snapping for as long as it is settling,
        // and the sound belongs to the moment it claims the scroll.
        final snapping = _scroll.isSnapping;
        if (snapping && !_wasSnapping) _sound(AudioCue.snap);
        _wasSnapping = snapping;
      },
      cameraBuilder: (_) {
        final camera = PerspectiveCamera(
          fovRadiansY: GalleryDimensions.fovRadians,
          // The camera crosses the same boundary as the room, or it would
          // pan away from the wall it is meant to be tracking.
          position: SceneAxes.position(_eye ?? _targetPose().position),
          target: SceneAxes.position(_look ?? _targetPose().target),
        );
        _lastCamera = camera;
        return camera;
      },
    );
  }

  /// Where the camera wants to be this frame.
  FocusPose _targetPose() {
    final frame = _focused;
    if (frame == null) {
      final pose = GalleryCameraPath.poseAt(_scroll.progress);
      return FocusPose(position: pose.position, target: pose.target);
    }

    return ProjectFocus.poseFor(
      frame,
      aspect: _viewSize.isEmpty ? 16 / 9 : _viewSize.width / _viewSize.height,
    );
  }

  /// The pose the camera is aiming for, orbit included.
  ///
  /// Once at the board the orbit owns the camera outright. It is seeded from
  /// exactly where the approach ends — same radius, same elevation — so the
  /// handover is a continuation rather than a cut.
  FocusPose _cameraTarget() {
    if (_focused == null && _atBoard) {
      final pose = GalleryCameraPath.orbitPose(
        _orbit.azimuth,
        _orbit.elevation,
      );
      return FocusPose(position: pose.position, target: pose.target);
    }
    return _targetPose();
  }

  /// Moves the camera toward where it wants to be.
  ///
  /// Frame-rate independent, rather than a fixed fraction per frame: the
  /// latter closes a different amount of the gap at 60fps than at 120, so
  /// the same move reads as a different speed on a different machine.
  void _advanceCamera(double dt) {
    final target = _cameraTarget();
    final eye = _eye ??= target.position.clone();
    final look = _look ??= target.target.clone();

    final rate = _focused != null ? focusApproach : corridorReturn;
    final t = 1 - math.exp(-rate * dt.clamp(0.0, 0.1));

    eye.setFrom(eye + (target.position - eye) * t);
    look.setFrom(look + (target.target - look) * t);
  }
}

/// Shown while the corridor is still being built.
///
/// Only reached on a machine slow enough that the scene has not finished by
/// the time the visitor arrives. It carries the ground colour of the stage
/// that just ended rather than the corridor's, so the wait continues from
/// what was on screen instead of cutting to a new plate.
class GalleryPlaceholder extends StatelessWidget {
  const GalleryPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: GalleryView.placeholderKey,
      color: context.colors.sceneBackground,
      child: const SizedBox.expand(),
    );
  }
}

/// Shown when the corridor cannot be built at all.
///
/// Deliberately plain and deliberately present: the alternative is a black
/// screen with no explanation, and a visitor who has scrolled this far has
/// earned being told what happened.
class GalleryFailure extends StatelessWidget {
  const GalleryFailure({required this.error, super.key});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colors.galleryFailureGround,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'The gallery failed to open:\n$error',
            textAlign: TextAlign.center,
            style: context.typography.galleryFailure,
          ),
        ),
      ),
    );
  }
}
