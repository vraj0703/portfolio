import 'dart:math' as math;
import 'dart:ui';

/// A point in the corridor, projected onto the screen.
class Projected {
  const Projected({
    required this.position,
    required this.scale,
    required this.depth,
    required this.isVisible,
  });

  /// Where it lands on screen.
  final Offset position;

  /// Size multiplier at this depth. Everything drawn at this point — a frame,
  /// its art, its light — multiplies its world size by this.
  final double scale;

  /// Distance in front of the camera. Used to paint back-to-front; nothing
  /// else should read it.
  final double depth;

  /// False when the point is behind the camera or past the far plane, in
  /// which case [position] and [scale] are meaningless.
  final bool isVisible;

  static const Projected hidden = Projected(
    position: Offset.zero,
    scale: 0,
    depth: double.infinity,
    isVisible: false,
  );
}

/// Projects the corridor's world space onto a 2D canvas.
///
/// Flame is a 2D engine, so the corridor is not rendered by a 3D pipeline —
/// it is projected. That works here because the camera is heavily
/// constrained: it walks forward looking straight down the corridor, then
/// pans sideways along the back wall. It never rotates freely, and a camera
/// that only translates needs nothing more than a pinhole divide to read as
/// genuinely spatial.
///
/// The trade is explicit: no free look, no roll, no oblique views. Everything
/// the gallery does is within that envelope.
///
/// World axes match the original scene: `x` right, `y` up, `z` *into* the
/// screen as it becomes more negative — so the camera advances by decreasing
/// its own `z`.
class CorridorProjection {
  const CorridorProjection({
    required this.viewport,
    required this.cameraX,
    required this.cameraY,
    required this.cameraZ,
    this.fovRadians = defaultFov,
  });

  /// 65 degrees, matching the original camera.
  static const double defaultFov = 65 * math.pi / 180;

  /// Nothing closer than this is drawn. Without a near plane, geometry level
  /// with the camera divides by ~zero and flings across the screen.
  static const double nearPlane = 0.35;

  /// Beyond this the corridor is fog anyway, and drawing it is wasted work.
  static const double farPlane = 90;

  final Size viewport;
  final double cameraX;
  final double cameraY;
  final double cameraZ;
  final double fovRadians;

  /// Distance from the eye to the projection plane, in world units, such that
  /// the viewport's height spans exactly [fovRadians].
  double get focalLength => (viewport.height / 2) / math.tan(fovRadians / 2);

  /// Projects a world point.
  Projected project(double x, double y, double z) {
    // Positive as the point recedes: the camera looks toward -z.
    final depth = cameraZ - z;
    if (depth < nearPlane || depth > farPlane) return Projected.hidden;

    final scale = focalLength / depth;

    return Projected(
      position: Offset(
        viewport.width / 2 + (x - cameraX) * scale,
        // Screen y grows downward while world y grows upward.
        viewport.height / 2 - (y - cameraY) * scale,
      ),
      scale: scale,
      depth: depth,
      isVisible: true,
    );
  }

  /// How much of the viewport's width a world-space span covers at [depth].
  ///
  /// Used to decide whether something is worth drawing before building its
  /// geometry.
  double screenWidthOf(double worldWidth, double depth) =>
      depth < nearPlane ? 0 : worldWidth * (focalLength / depth);

  /// Fog strength at [depth], `0` near and `1` fully swallowed.
  ///
  /// The original faded the corridor into the background colour rather than
  /// letting it recede to a hard vanishing point; without it the far end
  /// reads as a wall rather than as distance.
  static double fogAt(double depth, {double from = 25, double to = 80}) =>
      ((depth - from) / (to - from)).clamp(0.0, 1.0);
}
