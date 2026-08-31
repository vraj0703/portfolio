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

  /// How wide the testimonial alley is, front wall to back.
  ///
  /// Narrower than the corridor that feeds it. Standing in the skills hall
  /// and looking back down the alley, a wider one puts the far end of the
  /// project corridor — and the end of its right-hand wall — in view through
  /// the doorway, so the hall never reads as its own room. Six leaves the
  /// alley reading as a passage between two rooms rather than a window into
  /// the first one.
  static const double wingWidth = 6;

  /// How far from the back wall the forward walk stops.
  ///
  /// Half the alley, so the pan runs down its centre line. That is not just
  /// tidiness: the hall's doorway is cut on the same line, so an off-centre
  /// pan would arrive at the threshold offset from the opening and have to
  /// dogleg through it.
  static const double wallLockDistance = wingWidth / 2;
  static double get wallLockZ => backWallZ + wallLockDistance;

  /* -- Testimonial wing ------------------------------ */

  static const double testSpacing = 5;
  static const double testStartX = 7;

  /// How many frames hang on the far wall.
  ///
  /// Not taken from [GalleryTestimonials], deliberately. The frames are blank
  /// for now and the data still carries the full set plus its closing card,
  /// so deriving the count from it would run the wall — and the camera's pan
  /// along it — well past the last thing hanging there.
  static const int testimonialCount = 5;

  /// X coordinate the back-wall pan ends on — the last card, including CTA.
  static double get testPanEndX =>
      testStartX + (testimonialCount - 1) * testSpacing;

  /* -- Keyboard exhibition hall ---------------------- */

  /// The skills hall is a room, not a concourse.
  ///
  /// Across the visitor's view. This has been set four times and each one
  /// was a reaction to the last, so the whole range is worth keeping:
  ///
  ///  * **24**, square, as the previous site had it — a board adrift in nine
  ///    units of empty floor either side, under a ceiling only five high.
  ///    Warehouse proportions.
  ///  * **14**, which was right while the board was 6.3 across and too much
  ///    once it came down to 4.2.
  ///  * **12**, which crowded it the other way: the far wall is what the
  ///    board is *seen against*, and there was too little of it either side
  ///    for the room to read as a room rather than a corridor the board was
  ///    wedged into.
  ///  * **16**, here. Just under six units of wall on each side of the
  ///    board — room to stand in, short of the nine that left it adrift.
  ///
  /// The board's share of the width is the thing being tuned, and it is
  /// guarded in `skill_hall_test.dart` rather than left to memory.
  static const double kbWidth = 16;

  /// How deep it runs in the direction the visitor is facing.
  ///
  /// Shorter than it is wide, and deliberately: the board is met head-on, so
  /// depth is floor the visitor walks over rather than wall they look at.
  static const double kbDepth = 10;

  /// The hall opens 8 units past the final testimonial card.
  static double get kbX => testPanEndX + 8 + kbDepth / 2;
  /// The hall's centre line, which is the alley's, which is the pan's.
  ///
  /// Derived rather than restated so the three cannot drift apart — the
  /// straight run from the end of the pan into the hall depends on all of
  /// them being the same number.
  static double get kbZ => wallLockZ;
  /// How high the instruction is cut on the hall's far wall.
  ///
  /// Above the board, which hangs at [KeyboardLayout.hoverHeight] and tilts
  /// toward the visitor. Level with it the two would overlap from the
  /// doorway, and the line would be read through the keycaps.
  /// The middle of the wall, derived rather than dialled: halfway between
  /// the floor the visitor stands on and the ceiling above them. It sat at
  /// 2.4 — well above centre — because the first concern was clearing the
  /// board, and clearing it by more than was needed put the line up near the
  /// ceiling, where it read as signage bolted on rather than as part of the
  /// room.
  static const double instructionY = (floorY + ceilY) / 2;

  /// How high the "let's connect" sign hangs on the hall's entry wall.
  ///
  /// Level with the visitor at the board rather than with the corridor's
  /// pictures. They meet this sign from one place only — standing at the
  /// keyboard, turned back toward the door — and [KeyboardLayout.hoverHeight]
  /// plus the camera's rise above the board is where their eye is when they
  /// do. Hung at picture height it would sit below the frame on every screen.
  static const double connectSignY = 1.5;

  static double get kbEntryX => kbX - kbDepth / 2;
  static double get kbEndX => kbX + kbDepth / 2;
}
