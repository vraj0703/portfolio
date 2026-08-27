import 'package:vector_math/vector_math.dart';

import 'gallery_dimensions.dart';

/// Where the camera is and what it is looking at, at a point in the walk.
class CameraPose {
  const CameraPose({required this.position, required this.target});

  final Vector3 position;
  final Vector3 target;
}

/// The camera's route through the gallery, as a pure function of progress.
///
/// Two movements, not one: the visitor walks the length of the corridor
/// looking straight ahead, and then — once the far wall is close enough to
/// read — turns to it and tracks sideways along the testimonials. Splitting
/// them is what makes the space feel like a room rather than a rail; a single
/// interpolated path would cut the corner and clip the wall.
///
/// Kept as maths rather than state so the whole route can be inspected at any
/// point without walking it, and so the handover between the two movements
/// can be tested for continuity — the one place a two-part path visibly
/// breaks.
abstract final class GalleryCameraPath {
  /// Fraction of the walk spent moving down the corridor. The remainder pans
  /// the back wall.
  static const double walkFraction = 0.58;

  /// Eye height. Slightly below the frames' centre, so the work is read
  /// looking very slightly up — the way it hangs in a real room.
  static const double eyeHeight = 0.5;

  /// Where the visitor starts, just inside the entrance.
  static const double startZ = 3;

  /// How far ahead the camera looks while walking.
  static const double lookAhead = 10;

  /// Eye height for the wall pan, raised a touch to centre the cards.
  static const double panEyeHeight = 0.6;

  /// Where the camera stops along the back wall.
  static double get panEndX => GalleryDimensions.testPanEndX;

  /// The pose at [progress], `0`..`1`.
  static CameraPose poseAt(double progress) {
    final p = progress.clamp(0.0, 1.0);
    return p < walkFraction ? _walk(p) : _pan(p);
  }

  /// Down the corridor, looking straight ahead.
  ///
  /// The look target swings from "far down the corridor" to "the back wall"
  /// over the last stretch, so arriving at the end is a turn of attention
  /// rather than a stop. Squared, so the swing is imperceptible until the
  /// wall is genuinely close.
  static CameraPose _walk(double p) {
    final t = p / walkFraction;
    final z = startZ - t * (startZ - GalleryDimensions.wallLockZ);

    final proximity = ((p - 0.45) / 0.13).clamp(0.0, 1.0);
    final aheadZ = z - lookAhead;
    final lookZ =
        aheadZ + (GalleryDimensions.backWallZ - aheadZ) * proximity * proximity;

    // The eye rises to the pan's height over the same approach, so the two
    // movements meet at the same point rather than stepping. The original
    // relied on camera damping to smooth that step; making the path itself
    // continuous means it holds however the camera is driven.
    final eye = eyeHeight + (panEyeHeight - eyeHeight) * proximity;

    return CameraPose(
      position: Vector3(0, eye, z),
      target: Vector3(0, eye, lookZ),
    );
  }

  /// Sideways along the back wall, looking straight at it.
  ///
  /// Position and target share an x, so the wall is always viewed
  /// square-on. Letting the target lag would skew every card as it passed.
  static CameraPose _pan(double p) {
    final t = (p - walkFraction) / (1 - walkFraction);
    final x = t * panEndX;

    return CameraPose(
      position: Vector3(x, panEyeHeight, GalleryDimensions.wallLockZ),
      target: Vector3(x, panEyeHeight, GalleryDimensions.backWallZ),
    );
  }
}
