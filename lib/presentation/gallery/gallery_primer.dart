import 'package:flutter/widgets.dart';
import 'package:flutter_scene/scene.dart';
import 'package:portfolio/domain/gallery/gallery_camera_path.dart';
import 'package:portfolio/domain/gallery/gallery_dimensions.dart';
import 'package:portfolio/domain/interfaces/queuer.dart';
import 'package:portfolio/domain/models/loading_phase.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/gallery/gallery_scene_builder.dart';
import 'package:portfolio/presentation/gallery/scene_axes.dart';

/// Draws the finished corridor behind the loading curtain, so the first time
/// it is drawn is not the moment the visitor walks into it.
///
/// Building the gallery and *drawing* it are two different costs, and only
/// the first was being paid early. `GalleryScene.warmUp` runs during loading
/// and hands the view a finished scene synchronously, so nothing is assembled
/// at the transition — yet arriving still stuttered, because the first draw
/// of a material is where its pipeline gets compiled. That bill was landing
/// on the first frame in the corridor, which is the frame a visitor watches
/// most closely.
///
/// It is paid here instead, under a curtain that is already asking them to
/// wait. Loading takes a little longer; arriving takes none.
///
/// Two things make this work, and both have been got wrong before:
///
/// A warm-up that draws something *other* than what the visitor will see
/// compiles the wrong pipelines. An earlier attempt drew the skills board
/// from the corridor's start — thirty units away behind two walls, where
/// there is every chance it was culled and nothing was submitted at all. So
/// this renders the real scene through the real entry camera: same field of
/// view, same pose, same frustum, therefore the same nodes submitted.
///
/// And it must genuinely paint. `Offstage`, a zero-size box, or an `Opacity`
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

  /// How much of the screen the warm-up actually rasterises.
  ///
  /// Almost none. Which pipelines get compiled depends on the materials
  /// submitted, not on how many pixels they cover — and culling is decided by
  /// the view frustum, which does not change with raster size either. The
  /// same pipelines are built either way, so rendering the corridor at a
  /// twentieth scale keeps the warm-up from competing with the loading it is
  /// hiding behind.
  static const double pixelRatio = 0.05;

  /// How many frames count as warmed.
  ///
  /// A pipeline is compiled the first time it is drawn, so one frame is the
  /// whole of the work in principle. A few more because that first frame is
  /// where the compiling happens and is therefore the slow one: stopping on
  /// it hands its tail to the raster thread at the moment the curtain lifts,
  /// which moves the stutter rather than removing it.
  static const int warmFrames = 5;

  /// The corridor exactly as the visitor first meets it.
  ///
  /// `poseAt(0)` and the room's own field of view, so the frustum here is the
  /// frustum there. Anything this camera can see is a pipeline the arrival
  /// will not have to stop and compile.
  static PerspectiveCamera get entryCamera {
    final pose = GalleryCameraPath.poseAt(0);

    return PerspectiveCamera(
      fovRadiansY: GalleryDimensions.fovRadians,
      position: SceneAxes.position(pose.position),
      target: SceneAxes.position(pose.target),
    );
  }

  @override
  State<GalleryPrimer> createState() => _GalleryPrimerState();
}

class _GalleryPrimerState extends State<GalleryPrimer> {
  int _drawn = 0;
  bool _finished = false;
  bool _watching = false;

  /// Looks again next frame, until there is a scene to draw.
  ///
  /// Belt and braces, and the braces are the point: the curtain now *waits*
  /// on this widget, so a primer that misses its moment does not degrade the
  /// experience — it strands the visitor behind a bar that never fills.
  ///
  /// It missed it once already. The scene used to be published after the
  /// report that completes the gallery phase, and that report is the last
  /// thing to rebuild this tree — so the final build saw no scene, and there
  /// was no later change to wake it. That ordering is fixed, but relying on
  /// "some rebuild will happen at the right moment" is what failed, and this
  /// removes the dependency rather than re-tuning it.
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

    _drawn++;
    if (_drawn >= GalleryPrimer.warmFrames) _finished = true;

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

    return SceneView(
      gallery.scene,
      pixelRatio: GalleryPrimer.pixelRatio,
      camera: GalleryPrimer.entryCamera,
      // Counted from the render loop rather than from a timer: what is being
      // waited on is frames actually drawn, and a clock cannot tell the
      // difference between a frame and a stall.
      onTick: (_, _) => _countFrame(),
    );
  }
}
