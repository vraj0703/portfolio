import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:portfolio/domain/gallery/gallery_camera_path.dart';
import 'package:portfolio/domain/gallery/gallery_dimensions.dart';
import 'package:portfolio/domain/style/colors.dart';
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
  /// the point. Divided into a walk and a wall pan by [GalleryCameraPath].
  static const double scrollExtent = 6000;

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

  @override
  void dispose() {
    _gallery?.dispose();
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
    return Listener(
      onPointerSignal: (event) {
        if (event is! PointerScrollEvent) return;
        // Every event is offered to the gate, including the ones it
        // swallows — a continuous stream must not look like a pause simply
        // because none of it was acted on.
        if (!_gate.accept(_clock.elapsedMilliseconds)) return;
        // The driver clamps to `[0, extent]`, so scrolling the wrong way at
        // the entrance simply holds there rather than running off the start.
        _scroll.scrollBy(event.scrollDelta.dy * GalleryView.scrollDirection);
      },
      // Without this the placeholder is not a hit-test target, and the
      // events it is here to swallow go straight past it.
      behavior: HitTestBehavior.opaque,
      child: _surface(context),
    );
  }

  Widget _surface(BuildContext context) {
    final error = _error;
    if (error != null) return _failure(error);

    final gallery = _gallery;
    if (gallery == null) {
      // Only reached on a machine slow enough that the gallery is still
      // building when the visitor arrives. It carries the ground colour of
      // the stage that just ended rather than the corridor's, so the wait
      // continues from what was on screen instead of cutting to a new plate.
      return ColoredBox(
        key: GalleryView.placeholderKey,
        color: context.colors.sceneBackground,
        child: const SizedBox.expand(),
      );
    }

    return SceneView(
      gallery.scene,
      // Driven from the render loop rather than from setState. Rebuilding
      // this subtree every frame to move a camera re-runs the whole widget
      // tree sixty times a second for a value the renderer could read
      // directly — which is what made arriving here stutter.
      onTick: (elapsed, deltaSeconds) {
        _scroll.update(deltaSeconds);
        gallery.cue.update(elapsed.inMicroseconds / 1e6, _scroll.progress);
      },
      cameraBuilder: (_) {
        final pose = GalleryCameraPath.poseAt(_scroll.progress);
        return PerspectiveCamera(
          fovRadiansY: GalleryDimensions.fovRadians,
          // The camera crosses the same boundary as the room, or it would
          // pan away from the wall it is meant to be tracking.
          position: SceneAxes.position(pose.position),
          target: SceneAxes.position(pose.target),
        );
      },
    );
  }

  Widget _failure(Object error) {
    return ColoredBox(
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'The gallery failed to open:\n$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFE8C97A), fontSize: 13),
          ),
        ),
      ),
    );
  }
}
