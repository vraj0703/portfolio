import 'package:portfolio/domain/gallery/project_data.dart';
import 'package:portfolio/domain/gallery/testimonial_data.dart';

/// Corridor dimensions, ported from the React gallery's
/// `src/components/three/gallery/dimensions.ts`.
///
/// These are world-space units shared by the scene graph, the camera rig and
/// the click-to-focus maths. Several are *derived* from the content lists
/// rather than hard-coded — the corridor grows when a project is added — so
/// changing [GalleryProjects] physically moves walls. The parity tests in
/// `test/project/gallery/config/` pin those list lengths for that reason.
abstract final class GalleryDimensions {
  /* -- Corridor shell -------------------------------- */

  /// Corridor width and height.
  static const double corridorWidth = 8;
  static const double corridorHeight = 5;

  /// Half-width — the x offset of each side wall.
  static const double wallX = corridorWidth / 2;

  static const double floorY = -(corridorHeight / 2 - 1);
  static const double ceilY = corridorHeight / 2 + 1.5;

  /// Distance between consecutive frames along the corridor.
  static const double spacing = 5;

  /// Corridor runs the length of the left wall's frames plus a run-out.
  static double get corridorLength =>
      GalleryProjects.left.length * spacing + 8;

  /// The back wall sits 3 units short of the corridor's full length.
  static double get backWallZ => -(corridorLength - 3);

  /// The right wall stops early, opening the L into the testimonial wing.
  static double get rightWallLength =>
      GalleryProjects.right.length * spacing + 6;

  /* -- Frames ---------------------------------------- */

  static const double frameMaxHeight = 3.0;
  static const double frameDepth = 0.2;
  static const double frameBorder = 0.15;

  /// Frames hang slightly above the corridor's vertical centre.
  static const double frameY = 0.8;

  /* -- Camera ---------------------------------------- */

  /// Vertical field of view, in radians (65°, matching the R3F camera).
  static const double fovRadians = 65 * 3.141592653589793 / 180;

  /// Extra breathing room around a frame when the camera focuses it.
  static const double focusMargin = 1.5;

  /// How far from the back wall the forward walk stops.
  static const double wallLockDistance = 4;
  static double get wallLockZ => backWallZ + wallLockDistance;

  /* -- Testimonial wing ------------------------------ */

  static const double testSpacing = 5;
  static const double testStartX = 7;

  /// X coordinate the back-wall pan ends on — the last card, including CTA.
  static double get testPanEndX =>
      testStartX + (GalleryTestimonials.all.length - 1) * testSpacing;

  /* -- Keyboard exhibition hall ---------------------- */

  static const double kbRoom = 24;

  /// The hall opens 8 units past the final testimonial card.
  static double get kbX => testPanEndX + 8 + kbRoom / 2;
  static double get kbZ => backWallZ + corridorWidth / 2;
  static double get kbEntryX => kbX - kbRoom / 2;
  static double get kbEndX => kbX + kbRoom / 2;
}
