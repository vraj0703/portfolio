import 'package:flutter/widgets.dart';
import 'package:flutter_scene/scene.dart';
import 'package:portfolio/domain/gallery/gallery_shape.dart';
import 'package:portfolio/presentation/gallery/build_timing.dart';
import 'package:portfolio/domain/gallery/gallery_camera_path.dart';
import 'package:portfolio/domain/interfaces/queuer.dart';
import 'package:portfolio/domain/models/loading_phase.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/gallery/gallery_scene_builder.dart';
import 'package:portfolio/presentation/gallery/scene_axes.dart';

/// Draws the finished gallery behind the loading curtain, at its real size
/// and down its whole length, so that nothing the visitor meets in it is
/// drawn for the first time in front of them.
///
/// Building the gallery and *drawing* it are two different costs, and only
/// the first was being paid early. `GalleryScene.warmUp` runs during loading
/// and hands the view a finished scene synchronously, so nothing is assembled
/// at the transition. The first draw is a bill of its own: pipelines compiled
/// for each material, and the render targets the frame is drawn into
/// allocated and checked. It is paid here, under a curtain that is already
/// asking the visitor to wait. Loading takes a little longer; arriving takes
/// none.
///
/// Three things make this work, and each has been got wrong before:
///
/// **The real size.** A [Scene] keeps one set of render targets per view and
/// drops and rebuilds them whenever the size it is asked to draw at changes.
/// This drew at a twentieth of the pixels, and a one-pixel warm render ran
/// again during the title; the corridor's own first frame then asked for the
/// full size and paid for every target anew. On a phone that is four
/// full-screen multisampled buffers and their framebuffer checks: a
/// 0.4-0.9 s stall on arrival (ROG Phone II, 2026-11-17). Drawn here at the
/// device's own pixel ratio, through the same full-screen box, the targets
/// the corridor needs already exist when it arrives.
///
/// **Both ends, and no more.** `flutter_scene` culls against the view
/// frustum, so a node the camera cannot see is never submitted and never
/// warmed; parked at the entrance alone, an earlier warm-up moved the hitch
/// down the corridor. So the primer draws the entrance and the far end, one
/// frame each, counted in frames rather than time. A full-size frame is
/// expensive on a phone: a 28-frame walk added 9.5 s of loading on the ROG
/// (ms_ready 27.5 s to 37.0 s median), and two frames left no arrival stall
/// either (2026-11-17: no render target allocated after the tap in a GL
/// census, none in 3 device journeys, ms_ready 16.5 to 20.8 s).
///
/// **It must genuinely paint.** `Offstage`, a zero-size box, or an `Opacity`
/// of nothing all skip the raster stage, which is the whole of what is being
/// warmed. It is full size, and simply covered.
class GalleryPrimer extends StatefulWidget {
  const GalleryPrimer({required this.queuer, super.key});

  /// Where the frames drawn so far are reported.
  ///
  /// The curtain waits on [LoadingPhase.priming], and this is the only thing
  /// that can say when that is done — so a primer that never reports is a
  /// curtain that never lifts.
  final Queuer queuer;

  /// Frames along the corridor, entrance to the board, one viewpoint each:
  /// the two ends.
  static const int walkFrames = 2;

  /// Frames back at the entrance after the walk.
  ///
  /// None: the entrance is already the walk's first frame, and every extra
  /// full-size frame is loading the visitor waits through (see above).
  static const int settleFrames = 0;

  /// How many frames count as warmed.
  static const int warmFrames = walkFrames + settleFrames;

  /// Where along the corridor the primer stands on frame [frame]: the walk,
  /// then the entrance.
  static double progressFor(int frame) {
    if (frame >= walkFrames) return 0;
    return frame / (walkFrames - 1);
  }

  /// The camera on frame [frame], for a view of [aspect] (width over height).
  ///
  /// The room's own field of view and the path's own pose for this aspect,
  /// so the frustum here is the frustum there: a portrait phone walks the
  /// portrait path.
  static PerspectiveCamera cameraFor(
    GalleryShape shape,
    int frame, {
    double aspect = GalleryCameraPath.landscape,
  }) {
    final pose = GalleryCameraPath.poseAt(progressFor(frame), aspect: aspect);

    return PerspectiveCamera(
      fovRadiansY: shape.fovRadians,
      position: SceneAxes.position(pose.position),
      target: SceneAxes.position(pose.target),
    );
  }

  /// The corridor exactly as the visitor first meets it.
  static PerspectiveCamera entryCameraFor(
    GalleryShape shape, {
    double aspect = GalleryCameraPath.landscape,
  }) => cameraFor(shape, 0, aspect: aspect);

  @override
  State<GalleryPrimer> createState() => _GalleryPrimerState();
}

class _GalleryPrimerState extends State<GalleryPrimer> {
  int _drawn = 0;
  bool _finished = false;
  bool _watching = false;

  /// Looks again next frame, until there is a scene to draw.
  ///
  /// The curtain waits on this widget, so a primer that misses its moment
  /// does not degrade the experience — it strands the visitor behind a bar
  /// that never fills. It missed it once (the scene was published after the
  /// last rebuild of this tree), so this does not rely on "some rebuild will
  /// happen at the right moment".
  void _lookAgainNextFrame() {
    if (_watching) return;
    _watching = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _watching = false;
      if (mounted) setState(() {});
    });
  }

  void _countFrame() {
    if (_finished) return;

    if (_drawn == 0) BuildTiming.mark(BuildPhase.priming);
    _drawn++;
    if (_drawn >= GalleryPrimer.warmFrames) {
      _finished = true;
      BuildTiming.finish();
    }

    widget.queuer.queue(
      event: SceneEvent.loadingProgressed(
        phase: LoadingPhase.priming,
        value: (_drawn / GalleryPrimer.warmFrames).clamp(0.0, 1.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Nothing to draw until there is something built. This rebuilds with the
    // loading bar, so it starts the frame after the scene is finished.
    final gallery = GalleryScene.ready;
    if (gallery == null) {
      _lookAgainNextFrame();
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final aspect = size.isEmpty || !size.isFinite
            ? GalleryCameraPath.landscape
            : size.width / size.height;

        return SceneView(
          gallery.scene,
          // No pixelRatio: the device's own, which is what the corridor's
          // view uses. The size is the render targets' key, see above.
          cameraBuilder: (_) => GalleryPrimer.cameraFor(
            gallery.shape,
            // The frame about to be drawn. Held on the last once finished:
            // the curtain may take a moment more to lift.
            _drawn.clamp(0, GalleryPrimer.warmFrames - 1),
            aspect: aspect,
          ),
          // Counted from the render loop rather than from a timer: what is
          // being waited on is frames actually drawn, and a clock cannot tell
          // the difference between a frame and a stall.
          onTick: (_, _) => _countFrame(),
        );
      },
    );
  }
}
