import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:portfolio/domain/gallery/walk_order.dart';
import 'package:vector_math/vector_math.dart';
import 'package:portfolio/domain/gallery/control_layout.dart';
import 'package:portfolio/domain/gallery/gallery_camera_path.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';
import 'package:portfolio/domain/gallery/project_focus.dart';
import 'package:portfolio/domain/gallery/keyboard_orbit.dart';
import 'package:portfolio/domain/gallery/skill_data.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/gallery/frame_picker.dart';
import 'package:portfolio/presentation/gallery/gallery_overlay.dart';
import 'package:portfolio/domain/gallery/gallery_dimensions.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/domain/style/text_styles.dart';
import 'package:portfolio/domain/utils/scroll_driver.dart';
import 'package:portfolio/presentation/gallery/gallery_scene_builder.dart';
import 'package:portfolio/presentation/gallery/scene_axes.dart';
import 'package:portfolio/presentation/gallery/scroll_gate.dart';

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
    // No pauses: the corridor is a continuous walk, not a sequence of stops.
    // Halting the visitor at fixed frames would fight the scroll.
    snapPoints: const <double>[],
  );

  /// Keeps the gesture that ended the previous stage from driving this one.
  ///
  /// A fixed delay was not enough: a long, deliberate scroll outlasts any
  /// timeout and leaks through it. The gate waits for the input to go quiet
  /// instead, which is what actually separates one gesture from the next.
  final ScrollGate _gate = ScrollGate();

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
      kinds: const <SurfaceKind>{SurfaceKind.frame, SurfaceKind.exitSign},
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
      switch (control) {
        case ControlAction.previous:
          _step(_order.previous);
        case ControlAction.next:
          _step(_order.next);
        case ControlAction.exit:
          _focus(null);
      }
      return;
    }

    if (hit?.kind == SurfaceKind.exitSign) {
      context.read<SceneBloc>().add(const SceneEvent.galleryExited());
      return;
    }

    // A tap on the plaster is not a request to leave. Exiting is the ✕, and
    // dismissing on any miss would make the room feel like it was trying to
    // get rid of you.
    if (hit != null) _focus(hit);
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

    return row
        .firstWhere((p) => p.position == hit.position)
        .action;
  }

  @override
  void dispose() {
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

                // Only the board turns by dragging. Everywhere else in the
                // gallery a drag means nothing, and treating it as one would
                // fight the scroll.
                if (_inHall) {
                  _orbit.drag(event.delta.dx, event.delta.dy);
                }
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
              onBack: () => _step(_order.previous),
              onExit: () => _focus(null),
              onForward: () => _step(_order.next),
              mirrored: !(_focused?.position.x.isNegative ?? true),
              asFallback: _gallery?.controls == null,
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
      aspect: _viewSize.isEmpty
          ? 16 / 9
          : _viewSize.width / _viewSize.height,
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
      color: const Color(0xFF1A1A1A),
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
