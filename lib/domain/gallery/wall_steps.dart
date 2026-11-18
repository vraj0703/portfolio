import 'gallery_camera_path.dart';
import 'gallery_dimensions.dart';

/// The testimonial wall walked card by card.
///
/// Swiping or pushing the stick freely left the camera resting between two
/// cards, both cut by the screen's edge (mantr, 2026-11-18, on PR 19). On
/// the wall a sideways swipe, or a push of the stick, is a step: a timed
/// move (the title's strokes, [Strokes]) to the next card, centred and
/// whole; the other way is the previous card, and before the first card,
/// the back wall's statement.
abstract final class WallSteps {
  // -- The tuning, in one place. --------------------------------------------

  /// How far the stick has to be pushed to step.
  static const double stickThreshold = 0.5;

  /// How long a held stick rests on a card before stepping to the next.
  static const double restSeconds = 0.35;

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
  /// to the last card.
  static bool onWall(double at, List<double> points) =>
      at >= points.first - 1 && at <= points.last + 1;

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

  /// The way a stick pushed by [push] (`-1`..`1`) steps: `1`, `-1`, or `0`.
  static int stickDirection(double push) => push >= stickThreshold
      ? 1
      : push <= -stickThreshold
      ? -1
      : 0;
}
