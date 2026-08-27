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

  Future<void> _load() async {
    try {
      final gallery = await GalleryScene.warmUp();
      if (!mounted) {
        // Disposed while the build was in flight; nothing will ever show it,
        // so release it here rather than leaking a whole scene.
        gallery.dispose();
        return;
      }
      setState(() => _gallery = gallery);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  void dispose() {
    _gallery?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return _failure(_error!);

    final gallery = _gallery;
    if (gallery == null) {
      // Only reached on a machine slow enough that the gallery is still
      // building when the visitor arrives. It carries the ground colour of
      // the stage that just ended rather than the corridor's, so the wait
      // continues from what was on screen instead of cutting to a new plate.
      return ColoredBox(
        color: context.colors.sceneBackground,
        child: const SizedBox.expand(),
      );
    }

    return Listener(
      onPointerSignal: (event) {
        if (event is! PointerScrollEvent) return;
        // Every event is offered to the gate, including the ones it
        // swallows — a continuous stream must not look like a pause simply
        // because none of it was acted on.
        if (!_gate.accept(_clock.elapsedMilliseconds)) return;
        _scroll.scrollBy(event.scrollDelta.dy);
      },
      child: SceneView(
        gallery.scene,
        // Driven from the render loop rather than from setState. Rebuilding
        // this subtree every frame to move a camera re-runs the whole widget
        // tree sixty times a second for a value the renderer could read
        // directly — which is what made arriving here stutter.
        onTick: (elapsed, deltaSeconds) {
          _scroll.update(deltaSeconds);
          gallery.cue.update(
            elapsed.inMicroseconds / 1e6,
            _scroll.progress,
          );
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
      ),
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
