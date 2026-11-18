import 'gallery_camera_path.dart';
import 'gallery_dimensions.dart';

/// The testimonial wall's whole-card stops: the back wall's statement, then
/// each card centred.
///
/// A sideways swipe on the wall steps between them (a timed move, as the
/// title's strokes are). The stick glides along the wall by rate and, let
/// go, settles softly onto the nearest of them ([WalkControl.settleOn]).
abstract final class WallSteps {
  // -- The rules. -----------------------------------------------------------

  /// The scroll positions the wall is stepped through, for a gallery scroll
  /// of [extent]: the back wall's stop, then each card centred, the heading
  /// card first.
  static List<double> points(double extent) => <double>[
    GalleryCameraPath.walkFraction * extent,
    for (var i = 0; i < GalleryDimensions.testimonialCount; i++)
      progressAt(
            GalleryDimensions.testStartX + i * GalleryDimensions.testSpacing,
          ) *
          extent,
  ];

  /// The path's progress at which the pan is at [x] along the wall.
  static double progressAt(double x) =>
      GalleryCameraPath.walkFraction +
      x / GalleryCameraPath.panEndX * GalleryCameraPath.panFraction;

  /// Whether [at] (scroll units) is on the wall: from the back wall's stop
  /// (exactly: a walk still arriving there is not on the wall yet, or it
  /// would step past the statement instead of stopping at it) to the last
  /// card.
  static bool onWall(double at, List<double> points) =>
      at >= points.first - 1e-6 && at <= points.last + 1;

  /// The next step after [at], or null past the last card (or off the wall).
  static double? next(double at, List<double> points) {
    if (!onWall(at, points)) return null;
    for (final point in points) {
      if (point > at + 1) return point;
    }
    return null;
  }

  /// The step before [at], or null at the back wall (or off the wall).
  static double? previous(double at, List<double> points) {
    if (!onWall(at, points)) return null;
    for (final point in points.reversed) {
      if (point < at - 1) return point;
    }
    return null;
  }
}
