import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:portfolio/domain/gallery/card_homography.dart';
import 'package:portfolio/data/live_frame/corridor_frame.dart';
import 'package:portfolio/domain/gallery/live_frames.dart';
import 'package:portfolio/presentation/gallery/live_frame_overlay.dart';
import 'package:portfolio/domain/gallery/gallery_shape.dart';
import 'package:portfolio/domain/gallery/swipe_map.dart';
import 'package:portfolio/domain/gallery/wall_steps.dart';
import 'package:portfolio/domain/gallery/walk_control.dart';
import 'package:portfolio/domain/gallery/gallery_input.dart';
import 'package:portfolio/domain/gallery/testimonial_data.dart';
import 'package:portfolio/presentation/gallery/recommendation_form.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_scene/scene.dart';
import 'package:portfolio/data/analytics/analytics_setup.dart' show Browser;
import 'package:portfolio/data/di/dependency_manager.dart';
import 'package:portfolio/domain/contact/contact_links.dart';
import 'package:portfolio/domain/audio/app_audio.dart';
import 'package:portfolio/domain/gallery/control_layout.dart';
import 'package:portfolio/domain/gallery/gallery_camera_path.dart';
import 'package:portfolio/domain/config/logo_config.dart';
import 'package:portfolio/domain/analytics/analytics.dart';
import 'package:portfolio/presentation/analytics/site_telemetry.dart';
import 'package:portfolio/domain/gallery/gallery_dimensions.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';
import 'package:portfolio/domain/gallery/keyboard_orbit.dart';
import 'package:portfolio/domain/gallery/project_focus.dart';
import 'package:portfolio/domain/gallery/skill_data.dart';
import 'package:portfolio/domain/gallery/walk_order.dart';
import 'package:portfolio/domain/radio/radio_player.dart';
import 'package:portfolio/domain/radio/radio_station.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/domain/style/text_styles.dart';
import 'package:portfolio/domain/utils/crossing.dart';
import 'package:portfolio/domain/utils/frame_watch.dart';
import 'package:portfolio/domain/utils/scroll_driver.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/gallery/frame_picker.dart';
import 'package:portfolio/presentation/gallery/gallery_mark.dart';
import 'package:portfolio/presentation/gallery/gallery_overlay.dart';
import 'package:portfolio/presentation/gallery/gallery_scene_builder.dart';
import 'package:portfolio/presentation/gallery/scene_axes.dart';
import 'package:portfolio/presentation/gallery/testimonial_card.dart';
import 'package:portfolio/presentation/gallery/scroll_gate.dart';
import 'package:vector_math/vector_math.dart';

/// The gallery: a corridor of work the visitor walks through.
///
/// Stateful, and this is one of the cases that genuinely requires it. The
/// scene is built asynchronously, it owns GPU resources that must be released
/// on the way out, and the scroll position has to survive rebuilds.
class GalleryView extends StatefulWidget {
  const GalleryView({super.key});

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
  /// Whether the arrival event has gone out for this leaving: once.
  bool _arrivalRaised = false;

  /// The order the visitor steps through the work in — by depth down the
  /// corridor, both walls interleaved. See [FocusOrder].
  late final List<Placement> _pickable = GalleryLayout.build(shape: _shape);

  /// The shell and lens the scene was built for; the camera, picking and
  /// focus follow it so they agree with the walls.
  GalleryShape get _shape =>
      _gallery?.shape ?? GalleryScene.ready?.shape ?? GalleryShape.desktop;
  late final WalkOrder _order = WalkOrder(_pickable);

  /// The piece being read, or null while walking the corridor.
  Placement? _focused;

  /// The key the visitor last pressed on the skills board.
  Skill? _skill;

  /// Whether the camera is panning the testimonial wall. That pan is how the
  /// wall is read, with nothing focused, so it is what puts frame 1's button
  /// within reach: a press on it, or Enter, opens the form. Set every frame
  /// by the render loop; nothing rebuilds on it.
  bool _onWall = false;

  /// Takes Enter while the visitor is in the room, so a focused frame can be
  /// opened from the keyboard. Focused when the room opens; the overlay's own
  /// buttons, once tabbed to, keep their Enter for themselves.
  final FocusNode _keys = FocusNode(debugLabel: 'gallery');

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

  /// The thumb stick and the look (WalkControl), on a touch screen when the
  /// scene's rule says so (SceneState.walksByStick). The stick sets a
  /// walking rate; the frame advances the scroll by it. The look turns the
  /// head and eases back when let go.
  int? _stickPointer;
  Offset? _stickOrigin;

  /// The testimonial wall's steps ([WallSteps]), and when a held stick may
  /// take the next one (it rests on each card).
  late final List<double> _wallSteps = WallSteps.points(
    GalleryView.scrollExtent,
  );

  /// A per-frame probe of the walk, for measuring its feel on a phone: with
  /// `?pc-probe=1` each frame marks the page's timeline with the scroll and
  /// the eye, and the stick marks going down and up. Off otherwise.
  static final bool _probe = Uri.base.queryParameters.containsKey('pc-probe');

  /// How long the stick has been pushed near full (the run builds over it).
  double _runHeld = 0;

  /// Whether the camera is riding the path (the stick drives, no chase).
  bool _riding = false;

  /// Whether a stick let go on the wall is still to settle onto a card.
  bool _settleDue = false;

  /// Whether the stick may pick a frame by pushing sideways: once per push,
  /// re-armed when it comes back toward the middle.
  bool _sideArmed = true;

  /// The stick's push, two axes ([WalkControl.stick]).
  ({double x, double y}) _push = (x: 0, y: 0);
  double _walkSpeed = 0;

  /// A swipe above the stick ([SwipeMap]): the finger, where it set off,
  /// what it turned out to mean, and the way of travel on screen when it
  /// began. Replaces the look drag (Vishal, 2026-11-18).
  int? _swipePointer;
  Offset? _swipeFrom;
  SwipeIntent _swipeIntent = SwipeIntent.none;
  ScreenAxis _swipeAxis = (x: 0, y: 1);

  /// Where the stick is drawn: where the thumb landed, and the knob.
  final ValueNotifier<(Offset, Offset)?> _stick =
      ValueNotifier<(Offset, Offset)?>(null);

  /// Whether [event] is read by the stick and the swipes: a finger or a pen,
  /// with the scene's rule on. Where it lands decides which
  /// ([WalkControl.roleFor]).
  bool _walksByStick(PointerEvent event) =>
      (event.kind == PointerDeviceKind.touch ||
          event.kind == PointerDeviceKind.stylus) &&
      context.read<SceneBloc>().state.walksByStick;

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

  /// Where the focused frame's card is on the screen, while its live site
  /// is up (PORTFOLIO-6): a rectangle, so a notifier, not the bloc.
  final ValueNotifier<FocusedCard?> _liveRect = ValueNotifier<FocusedCard?>(
    null,
  );
  Size _viewSize = Size.zero;

  /// Clock the gate reasons in. Started with the view, so a gesture already
  /// in flight is measured from the moment the corridor appeared.
  final Stopwatch _clock = Stopwatch()..start();

  /// Reports frames the corridor spent too long on.
  ///
  /// Temporary. The hitch around the second or third picture has outlasted
  /// two explanations that both sounded right and were both wrong, so this
  /// is here to say *when* it happens rather than to guess again.
  final FrameWatch _frames = FrameWatch(label: 'gallery');

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _keys.requestFocus();
    });
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
  /// The corridor's shape for this screen, if this view starts the build
  /// (normally the loading screen already has).
  GalleryShape _shapeForScreen() {
    final size = MediaQuery.maybeSizeOf(context);
    if (size == null || size.isEmpty) return GalleryShape.desktop;
    return GalleryShape.forAspect(size.width / size.height);
  }

  void _load() {
    runZonedGuarded(
      () async {
        final gallery = await GalleryScene.warmUp(shape: _shapeForScreen());
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

    // The live site comes down the moment focus leaves its frame.
    _liveRect.value = null;
    context.read<SceneBloc>().queue(event: const SceneEvent.liveFrameEnded());
    setState(() => _focused = frame);
    _placeControls(frame);
    locate<SiteTelemetry>().onPiece(frame?.project?.id);
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
  /// The radio's play or stop: from the wall's button.
  void _toggleRadio() {
    _sound(AudioCue.click);
    final radio = locate<RadioPlayer>();

    // Not awaited, and said so. Opening a stream takes seconds; a tap
    // handler that waited on it would hold the corridor still while the
    // radio dialled out.
    final on = radio.state.isPlaying || radio.state.isTuning;
    // The bloc owns the radio: the press goes to it.
    context.read<SceneBloc>().queue(event: const SceneEvent.radioToggled());
    locate<SiteEvents>().radioToggled(on: !on, surface: 'wall');
  }

  /// The radio's next station: from the wall's button.
  void _nextStation() {
    _sound(AudioCue.click);
    final radio = locate<RadioPlayer>();
    unawaited(radio.next());
    locate<SiteEvents>().radioStationChanged(
      station: RadioDial.at(RadioDial.next(radio.state.station)).name,
      surface: 'wall',
    );
  }

  /// The way out: the BACK sign. One path out for every control: a request
  /// to the bloc, which marks the gallery as leaving; the lights-down runs
  /// from that ([_advanceLeaving]).
  void _exitGallery() => _requestExit(GalleryExit.title);

  void _requestExit(GalleryExit to) {
    // Once: a second press while the lights go down is the same press.
    if (context.read<SceneBloc>().state.galleryLeavingFor != null) return;
    _sound(AudioCue.pageTurn);
    context.read<SceneBloc>().queue(
      event: SceneEvent.galleryExitRequested(to: to),
    );
  }

  /// Opens the recommendation form.
  void _addYours() {
    if (!mounted) return;
    locate<SiteEvents>().testimonialFormOpened();
    unawaited(
      RecommendationForm.open(context, onSubmit: _submitRecommendation),
    );
  }

  /// What submitting the form does: LinkedIn opens first, inside the press,
  /// or the browser takes the new tab for a pop-up; then the words are
  /// copied for pasting there, kept in this browser, and put on frame 2.
  Future<void> _submitRecommendation(PendingRecommendation words) async {
    final events = locate<SiteEvents>()..testimonialLinkedinOpened();
    unawaited(locate<ContactLinks>().openLinkedIn());
    // Best effort: a browser may refuse the clipboard, and the words must
    // still be kept and shown — the form says where to paste them, and they
    // are on the wall to copy by hand.
    try {
      await Clipboard.setData(ClipboardData(text: words.clipboardText));
      // How long, bucketed; never the text.
      events.testimonialTextCopied(TextLength.of(words.clipboardText));
    } catch (_) {}
    locate<RecommendationStore>().save(words);
    await _gallery?.testimonials.show(words);
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
        SurfaceKind.testimonialFrame,
      },
    );

    // The wall is read by panning along it, not by focusing a frame, so the
    // pan is what puts frame 1's button within reach. Only the button opens
    // the form; a press anywhere else on the wall is not a request for it.
    if (hit?.kind == SurfaceKind.testimonialFrame) {
      if (_onWall && _onAddYours(hit!, at, camera)) {
        _sound(AudioCue.click);
        _addYours();
      }
      return;
    }

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
      _toggleRadio();
      return;
    }

    if (hit?.kind == SurfaceKind.radioNext) {
      _nextStation();
      return;
    }

    if (hit?.kind == SurfaceKind.exitSign) {
      _exitGallery();
      return;
    }

    if (hit?.kind == SurfaceKind.connectSign) {
      _requestExit(GalleryExit.contact);
      return;
    }

    // A tap on the plaster is not a request to leave. Exiting is the ✕, and
    // dismissing on any miss would make the room feel like it was trying to
    // get rid of you.
    if (hit == null) return;

    _sound(AudioCue.click);
    _focus(hit);
  }

  /// Whether [at] falls on the button drawn on [frame], if [frame] is the
  /// one that carries it (the invitation, frame 1).
  bool _onAddYours(Placement frame, Offset at, PerspectiveCamera camera) {
    if (_gallery == null || !_isInvitation(frame)) return false;
    final onCard = _onCard(frame, at, camera);
    if (onCard == null) return false;
    return TestimonialCard.buttonRegion(_bakedCard(frame)).contains(onCard);
  }

  /// Whether [frame] is the testimonial wall's first, the invitation.
  static bool _isInvitation(Placement frame) =>
      frame.kind == SurfaceKind.testimonialFrame &&
      frame.position.x ==
          GalleryDimensions.testStartX +
              TestimonialWall.invitation * GalleryDimensions.testSpacing;

  /// Where [at] lands on [frame]'s card, `0..1` from its top left, or null.
  ///
  /// The frame's screen rectangle gives where the press landed on the frame;
  /// the moulding is taken off each side to give where it landed on the
  /// card.
  Offset? _onCard(Placement frame, Offset at, PerspectiveCamera camera) {
    final onFrame = FramePicker.fractionWithin(
      at,
      frame,
      (world) => camera.worldToScreen(world, _viewSize),
    );
    if (onFrame == null) return null;
    final border = GalleryLayout.frameBorder;
    return Offset(
      (onFrame.dx * frame.extents.x - border) / (frame.extents.x - border * 2),
      (onFrame.dy * frame.extents.y - border) / (frame.extents.y - border * 2),
    );
  }

  /// The size [frame]'s card was baked at, which is the size its type and
  /// anything drawn on it were measured in.
  Size _bakedCard(Placement frame) {
    final border = GalleryLayout.frameBorder;
    final baked = (_gallery?.artworkSize ?? 0).toDouble();
    final ratio =
        (frame.extents.y - border * 2) / (frame.extents.x - border * 2);
    return Size(baked, (baked * ratio).roundToDouble());
  }

  /// Enter on the testimonial wall opens the form, as frame 1's button does.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.enter &&
        event.logicalKey != LogicalKeyboardKey.numpadEnter) {
      return KeyEventResult.ignored;
    }
    // At the testimonial wall, Enter is frame 1's button.
    if (_onWall) {
      _sound(AudioCue.click);
      _addYours();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
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
    // The scene says whether the gallery is leaving, and for where.
    final to = context.read<SceneBloc>().state.galleryLeavingFor;
    if (to == null || _arrivalRaised) return;

    final journeying = to == GalleryExit.contact;
    final duration = GalleryLeaving.durationFor(to);

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
    _arrivalRaised = true;
    if (mounted) {
      context.read<SceneBloc>().queue(event: GalleryLeaving.arrivalFor(to));
    }
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
    _liveRect.dispose();
    _keys.dispose();
    _radio?.cancel();
    _leaving.dispose();
    _stick.dispose();
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
    return Focus(
      focusNode: _keys,
      onKeyEvent: _onKey,
      child: LayoutBuilder(
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
                    GalleryInput.wheelStep(event.scrollDelta.dy),
                  );
                },
                // Without this the placeholder is not a hit-test target, and
                // the events it is here to swallow go straight past it.
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) {
                  _dragFrom = event.localPosition;
                  _dragDistance = 0;
                  if (!_walksByStick(event)) return;
                  switch (WalkControl.roleFor(
                    event.localPosition.dy,
                    _viewSize.height,
                    inHall: _inHall,
                  )) {
                    case TouchRole.stick:
                      _stickPointer = event.pointer;
                      if (_probe) Browser.mark('g down');
                      _stickOrigin = event.localPosition;
                      _stick.value = (event.localPosition, event.localPosition);
                    case TouchRole.swipe:
                      _swipePointer = event.pointer;
                      _swipeFrom = event.localPosition;
                      _swipeIntent = SwipeIntent.none;
                      _swipeAxis = _travelAxisNow();
                    case TouchRole.boardDrag:
                      // Left to the board's own drag below.
                      break;
                  }
                },
                onPointerMove: (event) {
                  final from = _dragFrom;
                  if (from == null) return;
                  _dragDistance += event.delta.distance;

                  // The stick sets a rate, it does not move anything: the
                  // frame walks by it ([WalkControl]).
                  if (event.pointer == _stickPointer) {
                    final origin = _stickOrigin!;
                    final d = event.localPosition - origin;
                    _push = WalkControl.stick(d.dx, d.dy);
                    final reach = WalkControl.stickRadius;
                    _stick.value = (
                      origin,
                      origin +
                          (d.distance > reach ? d / d.distance * reach : d),
                    );
                    return;
                  }
                  if (event.pointer == _swipePointer) {
                    _swiped(event);
                    return;
                  }

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
                  // hand rather than opposing it ([GalleryInput.dragStep]).
                  _scroll.scrollBy(GalleryInput.dragStep(event.delta.dy));
                },
                onPointerUp: (event) {
                  _letGo(event.pointer);
                  final dragged = _dragDistance > _tapSlop;
                  _dragFrom = null;
                  if (dragged) return;
                  _pick(event.localPosition);
                },
                onPointerCancel: (event) {
                  _dragFrom = null;
                  _letGo(event.pointer);
                },
                child: _surface(context),
              ),

              // The focused frame's live site over its card (PORTFOLIO-6),
              // above the scene and below the controls' fallback row.
              // Only once the corridor is built: before that there is no frame
              // to focus, and nothing for it to read.
              // The live site on its frame in the corridor: a full-screen
              // layer that takes no input.
              if (_gallery != null && _corridorLiveUrl != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CorridorFrame.view(
                      _corridorLiveUrl,
                      LiveFrames.virtualWidth,
                      LiveFrames.virtualHeight,
                      tint: LiveFrames.corridorTint,
                    ),
                  ),
                ),
              if (_gallery != null)
                Positioned.fill(child: LiveFrameOverlay(cardRect: _liveRect)),

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

              // The thumb stick, where the thumb landed: a plain ring and knob.
              IgnorePointer(
                child: ValueListenableBuilder<(Offset, Offset)?>(
                  valueListenable: _stick,
                  builder: (context, stick, _) => stick == null
                      ? const SizedBox.shrink()
                      : CustomPaint(
                          size: Size.infinite,
                          painter: _StickPainter(
                            origin: stick.$1,
                            knob: stick.$2,
                            ink: context.colors.galleryControlInk,
                          ),
                        ),
                ),
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
      ),
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
        // First thing in the frame, so what it measures is the gap between
        // frames rather than the part of one that happens to come after it.
        _frames.tick(
          'progress ${_scroll.progress.toStringAsFixed(3)} '
          'speed ${_scroll.velocity.abs().toStringAsFixed(0)} '
          '${_inHall ? 'hall' : 'corridor'}'
          '${_focused == null ? '' : ' focused'}',
        );

        // The scroll keeps running while a piece is focused, but it drives
        // nothing — so leaving focus hands the visitor back to exactly the
        // spot they left rather than to wherever the wheel wandered.
        _driveStick(deltaSeconds);

        if (_focused == null) {
          _scroll.update(deltaSeconds, tight: _stickDriving);
        }
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

        // The pending card's entrance, and whether the wall is in front of
        // the visitor for the "add yours" control.
        gallery.testimonials.tick(deltaSeconds);
        final wallProgress = _scroll.progress;
        _onWall =
            _focused == null &&
            wallProgress >= GalleryCameraPath.walkFraction &&
            wallProgress <= GalleryCameraPath.panEnd;
        // Where in the gallery, for the journey; a no-op unless it changed.
        locate<SiteTelemetry>().onRegion(
          _onWall
              ? SitePath.testimonials
              : _inHall
              ? SitePath.skills
              : null,
        );

        if (!_atBoard) {
          // Leaving. Eased back to the doorway view so a reverse scroll walks
          // the visitor out facing the way they came, rather than sideways
          // from wherever they had wandered round to.
          _orbit.settle(deltaSeconds);
        } else if (_dragFrom == null || _stickPointer != null) {
          // The stick walking to the board is not a hand on the board.
          _orbit.update(deltaSeconds);
        }
        _advanceCamera(deltaSeconds);
        _arriveLive();
        _placeCorridorLive();
        if (_probe) {
          final eye = _eye;
          Browser.mark(
            'g ${_scroll.offset.toStringAsFixed(2)} '
            '${seconds.toStringAsFixed(5)} '
            '${eye?.x.toStringAsFixed(4)} ${eye?.z.toStringAsFixed(4)}',
          );
        }
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
        final camera = _cameraNow();
        _lastCamera = camera;
        return camera;
      },
    );
  }

  /// The camera this frame draws with. Built from the pose the tick has just
  /// advanced, so whatever is laid over the scene from the tick (the
  /// corridor's live page) uses the very camera the frame is drawn with,
  /// not the last frame's.
  PerspectiveCamera _cameraNow() => PerspectiveCamera(
    fovRadiansY: _shape.fovRadians,
    // The camera crosses the same boundary as the room, or it would
    // pan away from the wall it is meant to be tracking.
    position: SceneAxes.position(_eye ?? _targetPose().position),
    target: SceneAxes.position(_look ?? _targetPose().target),
  );

  /// The view's shape, width over height; a laptop's before the first
  /// layout.
  double get _aspect => _viewSize.isEmpty
      ? GalleryCameraPath.landscape
      : _viewSize.width / _viewSize.height;

  /// Where the camera wants to be this frame.
  FocusPose _targetPose() {
    final frame = _focused;
    if (frame == null) {
      final pose = GalleryCameraPath.poseAt(_scroll.progress, aspect: _aspect);
      return FocusPose(position: pose.position, target: pose.target);
    }

    return ProjectFocus.poseFor(
      frame,
      aspect: _viewSize.isEmpty ? 16 / 9 : _viewSize.width / _viewSize.height,
      shape: _shape,
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
        aspect: _aspect,
      );
      return FocusPose(position: pose.position, target: pose.target);
    }
    return _targetPose();
  }

  /// Whether the thumb stick is moving the visitor: held, or still easing
  /// out. While it is, the scroll and the camera follow it tightly, so a
  /// release stops the walk instead of letting it glide.
  bool get _stickDriving =>
      _stickPointer != null || _walkSpeed != 0 || _scroll.isMoving;

  /// Lets go of whatever [pointer] was holding: the stick stops pushing
  /// (the walk eases out) and the look eases back in the frame.
  void _letGo(int pointer) {
    if (pointer == _stickPointer) {
      if (_probe) Browser.mark('g up');
      _stickPointer = null;
      _settleDue = true;
      _sideArmed = true;
      _push = (x: 0, y: 0);
      _stick.value = null;
    }
    if (pointer == _swipePointer) {
      _swipePointer = null;
      _swipeFrom = null;
    }
  }

  /// The way of travel on screen, here: from the path a step ahead and
  /// where the camera is looking.
  ScreenAxis _travelAxisNow() {
    final progress = _scroll.progress;
    final here = GalleryCameraPath.poseAt(progress, aspect: _aspect);
    final ahead = GalleryCameraPath.poseAt(
      math.min(1, progress + 0.002),
      aspect: _aspect,
    );
    return SwipeMap.travelAxis(
      ahead.position - here.position,
      here.target - here.position,
    );
  }

  /// A swipe's move: decided once it has gone far enough, then followed.
  void _swiped(PointerMoveEvent event) {
    final from = _swipeFrom;
    if (from == null) return;

    if (_swipeIntent == SwipeIntent.none) {
      final d = event.localPosition - from;
      _swipeIntent = SwipeMap.classify(d.dx, d.dy, _swipeAxis);
      switch (_swipeIntent) {
        case SwipeIntent.none:
          return;
        case SwipeIntent.travel:
          if (_focused != null) _focus(null);
          // On the wall, one swipe is one step to the next card (or back).
          if (_swipeStep(SwipeMap.onward(d.dx, d.dy, _swipeAxis))) {
            _swipeIntent = SwipeIntent.none;
            _swipeFrom = null;
            return;
          }
          // Everything so far, then every move after it.
          _travel(d.dx, d.dy);
          return;
        case SwipeIntent.focusLeft:
        case SwipeIntent.focusRight:
          _focusSide(right: _swipeIntent == SwipeIntent.focusRight);
          return;
      }
    }
    if (_swipeIntent == SwipeIntent.travel) {
      _travel(event.delta.dx, event.delta.dy);
    }
  }

  /// A swipe's step along the testimonial wall, if it is on the wall and
  /// there is a card that way: true if it took it (or one is playing).
  bool _swipeStep(double onward) {
    final at = _scroll.target;
    if (!WallSteps.onWall(at, _wallSteps)) return false;
    if (_scroll.isMoving) return true;
    final to = onward > 0
        ? WallSteps.next(at, _wallSteps)
        : WallSteps.previous(at, _wallSteps);
    if (to == null) return false;
    _scroll.moveTo(to);
    return true;
  }

  /// The stick, every frame: in the corridor a sideways push turns to the
  /// nearest frame on that side; everywhere it walks by rate along the way
  /// of travel (up the corridor, along the wall), eased in and out; let go
  /// on the wall, it settles onto the nearest whole card.
  void _driveStick(double dt) {
    final held = _stickPointer != null;
    final push = held ? _push : (x: 0.0, y: 0.0);
    final (ahead, behind) = _axesNow();

    // Sideways in the corridor: a frame. Pushing the other way, or up or
    // down, leaves it and carries on.
    if (held && !_inHall) {
      final side = WalkControl.side(
        push,
        ahead,
        at: _scroll.target,
        backWallStop: GalleryView.backWallStop,
      );
      final current = _focused;
      if (current != null) {
        final otherWay =
            side != 0 && current.position.x.isNegative == (side > 0);
        if (otherWay || push.y.abs() > 0.5) _focus(null);
      } else if (side != 0 && _sideArmed) {
        _sideArmed = false;
        _focusSide(right: side > 0);
      }
      if (push.x.abs() < WalkControl.sideRearm) _sideArmed = true;
    }

    // The camera rides the path while the stick drives. Riding starts once
    // the camera is on the path (easing out of a focused frame, the walk
    // waits for it) and holds for as long as the stick drives: the walk moves
    // the path a little each frame, so "on the path" is a state, not a
    // distance checked every frame (checked every frame, it stalled the walk
    // to a crawl on the ROG).
    if (!_stickDriving || _focused != null) {
      _riding = false;
    } else if (!_riding && _cameraGap() < WalkControl.rideGap) {
      _riding = true;
    }
    final rate = _focused == null && _riding
        ? WalkControl.rate(
            push,
            ahead,
            behind,
            pastCorner: _scroll.target > GalleryView.backWallStop + 1,
          )
        : 0.0;
    // The run: how long the push has been held near full.
    _runHeld = rate.abs() >= WalkControl.runFrom ? _runHeld + dt : 0;
    _walkSpeed = WalkControl.speedTowards(
      _walkSpeed,
      WalkControl.targetSpeed(rate, _runHeld),
      dt,
    );
    if (_walkSpeed != 0 &&
        _focused == null &&
        _gate.accept(_clock.elapsedMilliseconds)) {
      final want = _walkSpeed * dt;
      final step = WalkControl.stepToStop(
        _scroll.target,
        want,
        GalleryView.backWallStop,
      );
      _scroll.scrollBy(step);
      // Arrived at the back wall walking up the corridor: the walk stops
      // there unless the push already runs along the wall (a diagonal), in
      // which case it glides straight on.
      if (step != want) {
        final (aheadAtWall, behindAtWall) = _axesAt(GalleryView.backWallStop);
        if (WalkControl.rate(push, aheadAtWall, behindAtWall) <= 0) {
          _walkSpeed = 0;
        }
      }
    }

    // Let go on the wall: once the walk has eased out, a soft settle onto the
    // nearest whole card. Never while the stick is held.
    if (!held &&
        _settleDue &&
        _walkSpeed == 0 &&
        !_scroll.isMoving &&
        _focused == null) {
      _settleDue = false;
      final to = WalkControl.settleOn(_scroll.target, _wallSteps);
      if (to != null && (to - _scroll.target).abs() > 1) {
        _scroll.moveTo(to, seconds: WalkControl.settleSeconds);
      }
    }
  }

  /// The way of travel on screen ahead of the visitor and behind them, here.
  (ScreenAxis, ScreenAxis) _axesNow() =>
      _axesAt(_scroll.progress * GalleryView.scrollExtent);

  /// The same at scroll position [at].
  (ScreenAxis, ScreenAxis) _axesAt(double at) {
    const step = 1.0; // scroll units: a hair either side of the point
    double p(double units) =>
        (units / GalleryView.scrollExtent).clamp(0.0, 1.0);
    final here = GalleryCameraPath.poseAt(p(at), aspect: _aspect);
    final look = here.target - here.position;
    return (
      SwipeMap.travelAxis(GalleryCameraPath.headingAt(p(at + step)), look),
      SwipeMap.travelAxis(GalleryCameraPath.headingAt(p(at - step)), look),
    );
  }

  void _travel(double dx, double dy) {
    // A step playing on the wall is not interrupted by the rest of a swipe.
    if (_scroll.isMoving) return;
    if (!_gate.accept(_clock.elapsedMilliseconds)) return;
    _scroll.scrollBy(SwipeMap.onward(dx, dy, _swipeAxis));
  }

  /// A sideways swipe in the corridor: the nearest frame on that side comes
  /// into focus, or, if a frame on the other side is focused, the swipe back
  /// leaves it.
  void _focusSide({required bool right}) {
    final current = _focused;
    if (current != null) {
      if (current.position.x.isNegative == right) _focus(null);
      return;
    }
    final z = (_eye ?? _targetPose().position).z;
    final frame = _order.nearestOn(right: right, z: z);
    if (frame == null) return;
    _sound(AudioCue.click);
    _focus(frame);
  }

  /// Moves the camera toward where it wants to be.
  ///
  /// Frame-rate independent, rather than a fixed fraction per frame: the
  /// latter closes a different amount of the gap at 60fps than at 120, so
  /// the same move reads as a different speed on a different machine.
  /// The focused frame's live site, once the camera has arrived square to
  /// it (PORTFOLIO-6): asks the scene for it, and keeps the card's screen
  /// rectangle where the iframe lies. Before arrival the card is still
  /// turning on the screen and an iframe could not lie flat over it.
  void _arriveLive() {
    final frame = _focused;
    final id = frame?.project?.id;
    final camera = _lastCamera;
    if (frame == null || id == null || camera == null) return;
    // A frame with a site gets the link to it; one that may be framed gets
    // the site itself as well.
    if (LiveFrames.siteFor(id) == null) return;
    if (_cameraGap() > LiveFrames.arrivalGap) return;
    final rect = FramePicker.cardRectOf(
      frame,
      (world) => camera.worldToScreen(world, _viewSize),
    );
    final card = rect == null ? null : FocusedCard(projectId: id, rect: rect);
    if (card != _liveRect.value) _liveRect.value = card;
    if (LiveFrames.urlFor(id) == null) return;
    // Not on a phone, for now: the page scaled to a phone's frame is too
    // small to use (PORTFOLIO-6). A phone keeps the picture and "open site"
    // while Vishal picks between a full-screen sheet and pinch to zoom.
    if (Browser.isPhone()) return;
    final bloc = context.read<SceneBloc>();
    final state = bloc.state;
    if (state is Gallery && state.live.projectId != id) {
      bloc.queue(event: SceneEvent.liveFrameRequested(projectId: id));
    }
  }

  /// The live site on its corridor frame, in perspective: the card's
  /// corners projected by the camera this frame is drawn with, and the
  /// homography that lays the page on them. The picture shows instead when
  /// the card is behind the camera, facing away, small on the screen (the
  /// hybrid), or focused (the axis-aligned live layer takes it then).
  void _placeCorridorLive() {
    final frame = _corridorLiveFrame;
    if (_lastCamera == null || _corridorLiveUrl == null || frame == null) {
      return;
    }
    if (_focused?.project?.id == frame.project?.id) {
      CorridorFrame.place(null);
      return;
    }
    final camera = _cameraNow();
    final halfW = frame.extents.x / 2 - GalleryLayout.frameBorder;
    final halfH = frame.extents.y / 2 - GalleryLayout.frameBorder;
    final p = frame.position;
    final eye = _eye ?? _targetPose().position;
    final placement = corridorPlacement(
      corners: <(double, double)?>[
        for (final (dy, dz) in <(double, double)>[
          (halfH, -halfW),
          (halfH, halfW),
          (-halfH, halfW),
          (-halfH, -halfW),
        ])
          switch (camera.worldToScreen(
            SceneAxes.position(Vector3(p.x, p.y + dy, p.z + dz)),
            _viewSize,
          )) {
            final s? => (s.dx, s.dy),
            null => null,
          },
      ],
      // A frame hangs on a side wall and faces the corridor: the eye must
      // be on the corridor's side of that wall.
      facing: (eye.x - p.x) * -p.x.sign > 0,
      viewWidth: _viewSize.width,
      viewHeight: _viewSize.height,
      pageWidth: LiveFrames.virtualWidth.toDouble(),
      pageHeight: LiveFrames.virtualHeight.toDouble(),
      shareFrom: LiveFrames.corridorShareFrom,
      shareFull: LiveFrames.corridorShareFull,
    );
    CorridorFrame.place(placement?.matrix, opacity: placement?.opacity ?? 0);

    // Seen: the page loaded and fully up on its frame, once a visit.
    final ms = CorridorFrame.loadedMs;
    if (!_corridorLiveSeen && ms != null && (placement?.opacity ?? 0) >= 1) {
      _corridorLiveSeen = true;
      locate<SiteEvents>().projectLiveViewed(
        frame.project!.id,
        msToLoad: ms,
        where: LiveWhere.corridor,
      );
    }
  }

  bool _corridorLiveSeen = false;

  /// The frame whose live site shows in the corridor, and its URL: a
  /// frameable site, on a desktop or a tablet (a phone keeps the picture).
  late final Placement? _corridorLiveFrame = _pickable
      .where((p) => p.project?.id == _corridorLiveId)
      .firstOrNull;
  static const String _corridorLiveId = 'shunya-systems';
  late final String? _corridorLiveUrl = Browser.isPhone()
      ? null
      : LiveFrames.urlFor(_corridorLiveId);

  /// How far the camera is from where the path puts it (world units).
  double _cameraGap() {
    final eye = _eye;
    if (eye == null) return 0;
    return (_cameraTarget().position - eye).length;
  }

  void _advanceCamera(double dt) {
    final target = _cameraTarget();
    final eye = _eye ??= target.position.clone();
    final look = _look ??= target.target.clone();

    // The stick (and the moves it and a swipe make): the camera is the path,
    // the walk's own ease the only smoothing. Everything else keeps its chase.
    if (_riding && _focused == null) {
      eye.setFrom(target.position);
      look.setFrom(target.target);
      return;
    }
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

/// The thumb stick: a ring where the thumb landed and a knob where it is.
class _StickPainter extends CustomPainter {
  const _StickPainter({
    required this.origin,
    required this.knob,
    required this.ink,
  });

  final Offset origin;
  final Offset knob;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..drawCircle(
        origin,
        WalkControl.stickRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = ink.withValues(alpha: 0.5),
      )
      ..drawCircle(knob, 18, Paint()..color = ink.withValues(alpha: 0.6));
  }

  @override
  bool shouldRepaint(_StickPainter old) =>
      old.origin != origin || old.knob != knob || old.ink != ink;
}

/// The gallery's way out, as rules: how long the lights take to go down for
/// each destination, and the event that arrives there when they have.
abstract final class GalleryLeaving {
  static Duration durationFor(GalleryExit to) => switch (to) {
    GalleryExit.title => GalleryView.leaving,
    GalleryExit.contact => GalleryView.leavingWithMark,
  };

  static SceneEvent arrivalFor(GalleryExit to) => switch (to) {
    GalleryExit.title => const SceneEvent.galleryExited(),
    GalleryExit.contact => const SceneEvent.contactRequested(),
  };
}
