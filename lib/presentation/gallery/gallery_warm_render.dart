import 'package:flutter/widgets.dart';
import 'package:flutter_scene/scene.dart';
import 'package:portfolio/domain/gallery/gallery_camera_path.dart';
import 'package:portfolio/domain/gallery/gallery_dimensions.dart';
import 'package:portfolio/presentation/gallery/gallery_scene_builder.dart';
import 'package:portfolio/presentation/gallery/scene_axes.dart';

/// Draws the finished gallery at one pixel, behind everything, before the
/// visitor gets there.
///
/// Building the scene ahead of time is not the same as having drawn it.
/// Assembling the graph is CPU work, and that is what the loading bar already
/// covers; the rest of the cost only lands on the first *frame* that submits
/// it — shader variants compiled for each material, textures uploaded from
/// host memory to the GPU, pipeline state resolved. That bill is paid on
/// whichever frame draws the corridor first, and if that is the frame the
/// visitor arrives on, they see the hitch.
///
/// So it is paid here instead, during the intro, on a surface too small to
/// cost anything and hidden behind the stage that is already on screen.
/// Pipeline compilation is keyed by material, not by viewport, so one pixel
/// warms exactly what a full screen would.
class GalleryWarmRender extends StatelessWidget {
  const GalleryWarmRender({super.key});

  /// Small enough to be free, but not zero — a zero-area surface is skipped
  /// before it reaches the GPU, which would warm nothing at all.
  ///
  /// Applied by the caller through a [Positioned]. Sizing it from inside is
  /// not enough: an expanding [Stack] hands its unpositioned children tight
  /// constraints, and a [SizedBox] under those is simply overruled.
  static const double edge = 1;

  @override
  Widget build(BuildContext context) {
    final gallery = GalleryScene.ready;
    if (gallery == null) return const SizedBox.shrink();

    return SceneView(
      gallery.scene,
      // Framed on the corridor entrance: the first thing the visitor will
      // actually see, and so the set of materials worth warming first.
      cameraBuilder: (_) {
        final pose = GalleryCameraPath.poseAt(0);
        return PerspectiveCamera(
          fovRadiansY: GalleryDimensions.fovRadians,
          position: SceneAxes.position(pose.position),
          target: SceneAxes.position(pose.target),
        );
      },
    );
  }
}
