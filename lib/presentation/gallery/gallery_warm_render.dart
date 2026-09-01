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
///
/// The camera *walks* the corridor rather than standing at its mouth, and
/// that is not thoroughness for its own sake: `flutter_scene` culls against
/// the view frustum, so a node the warm camera cannot see is never submitted
/// and never warmed. Parked at the entrance this warmed the first wall and
/// nothing else — and the hitch simply moved down the corridor to the second
/// or third picture, which is exactly where it was reported.
class GalleryWarmRender extends StatelessWidget {
  const GalleryWarmRender({super.key});

  /// Small enough to be free, but not zero — a zero-area surface is skipped
  /// before it reaches the GPU, which would warm nothing at all.
  ///
  /// Applied by the caller through a [Positioned]. Sizing it from inside is
  /// not enough: an expanding [Stack] hands its unpositioned children tight
  /// constraints, and a [SizedBox] under those is simply overruled.
  static const double edge = 1;

  /// How long the warm camera takes to walk the whole corridor.
  ///
  /// Short, because every frame of it is a frame the intro is also drawing.
  /// It only has to be long enough that no stretch of wall is skipped over
  /// between one frame and the next — at sixty a second this is well over a
  /// hundred viewpoints, against seven pictures and two rooms.
  static const Duration sweep = Duration(seconds: 2);

  /// Where along the corridor the warm camera stands at [elapsed].
  ///
  /// Runs once and then holds at the far end rather than looping: everything
  /// has been submitted by then, and a camera still moving behind the curtain
  /// is work with nothing left to warm.
  static double progressAt(Duration elapsed) =>
      (elapsed.inMicroseconds / sweep.inMicroseconds).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final gallery = GalleryScene.ready;
    if (gallery == null) return const SizedBox.shrink();

    return SceneView(
      gallery.scene,
      // Walked, not parked. The visitor's own journey is what decides which
      // materials they meet, so the warm-up takes the same journey — the
      // pictures down the corridor, the turn into the wing, and the board in
      // the hall are each brought into frame and drawn once.
      cameraBuilder: (elapsed) {
        final pose = GalleryCameraPath.poseAt(progressAt(elapsed));
        return PerspectiveCamera(
          fovRadiansY: GalleryDimensions.fovRadians,
          position: SceneAxes.position(pose.position),
          target: SceneAxes.position(pose.target),
        );
      },
    );
  }
}
