import 'dart:math' as math;

import 'gallery_dimensions.dart';

/// The corridor's shell and lens for a screen of a given aspect.
///
/// A laptop gets [desktop], today's numbers exactly. A portrait phone sees
/// only about 32 degrees across at the desktop's 65-degree vertical field,
/// so in an 8 m corridor the frames on either wall sat at the screen's edges
/// or off it. [portrait] narrows the corridor, lowers the ceiling a little
/// and opens the lens, so the frames on both walls are in view.
///
/// The floor stays where it is at every aspect: the hall's keyboard and the
/// scroll arrow stand on it. The walls already rise past the ceiling, so a
/// lower ceiling needs no change to them.
///
/// Chosen once, when the scene is built (it is built once and kept): a phone
/// turned sideways after that keeps the shape it loaded with.
class GalleryShape {
  const GalleryShape({
    required this.corridorWidth,
    required this.ceilY,
    required this.fovDegrees,
  });

  /// Today's corridor, unchanged.
  static const GalleryShape desktop = GalleryShape(
    corridorWidth: GalleryDimensions.corridorWidth,
    ceilY: GalleryDimensions.ceilY,
    fovDegrees: GalleryDimensions.fovDegrees,
  );

  /// A screen taller than it is wide.
  static const GalleryShape portrait = GalleryShape(
    // Narrow enough that a frame across the corridor is in view, wide enough
    // that the focus pose (which backs off until the frame's width fits)
    // still stands inside the opposite wall at 21:9. See gallery_shape_test.
    corridorWidth: 6.5,
    ceilY: GalleryDimensions.ceilY - portraitCeilingDrop,
    fovDegrees: 78,
  );

  /// How much lower the portrait ceiling hangs: less of a phone's tall
  /// screen goes to tiles overhead.
  static const double portraitCeilingDrop = 0.5;

  /// The shape for a screen of width / height [aspect].
  static GalleryShape forAspect(double aspect) =>
      aspect < 1 ? portrait : desktop;

  final double corridorWidth;

  /// The underside of the ceiling.
  final double ceilY;

  /// The vertical field of view.
  final double fovDegrees;

  double get wallX => corridorWidth / 2;

  double get fovRadians => fovDegrees * math.pi / 180;
}
