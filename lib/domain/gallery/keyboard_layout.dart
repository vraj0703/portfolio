import 'package:vector_math/vector_math.dart';

import 'gallery_dimensions.dart';
import 'skill_data.dart';

/// One keycap, placed on the board.
class KeyPlacement {
  const KeyPlacement({
    required this.skill,
    required this.row,
    required this.column,
    required this.position,
    required this.extents,
  });

  final Skill skill;

  /// Which row this cap is in, and its place along it.
  ///
  /// [row] picks the metal the cap is cut from. [column] is carried for the
  /// boot-up sweep that is not built yet — when it is, it runs corner to
  /// corner rather than row by row, because a diagonal reads as something
  /// powering on where row by row reads as a list being printed, and the sum
  /// of the two is what orders it.
  final int row;
  final int column;

  /// Centre of the cap, in the board's own space — origin at the board's
  /// middle, `y` up, `z` running from the near row to the far one.
  final Vector3 position;
  final Vector3 extents;
}

/// The skills keyboard: a board of keycaps, one per skill.
///
/// Pure arrangement, like the corridor's. The failures worth catching here
/// are quiet ones — a row centred on the wrong width sits visibly off to one
/// side, and a cap pitch that disagrees with the case leaves the outer keys
/// hanging over the edge. Neither throws, and neither is obvious from inside
/// a running scene.
abstract final class KeyboardLayout {
  /// Pitch of one key, and the gap between neighbours. A cap is smaller than
  /// its unit by exactly the gap, which is what makes the gaps even.
  static const double keyUnit = 0.9;
  static const double keyGap = 0.1;
  static const double keyHeight = 0.35;
  static double get keyStep => keyUnit + keyGap;
  static double get capSize => keyUnit - keyGap;

  /// Border of case around the outermost keys, at the ends of the rows and
  /// beyond the front and back rows.
  ///
  /// Narrower across than along. The rows taper 8/7/6/5, so the case has to
  /// be cut for the widest of them while most of what the visitor sees is the
  /// short near row — which leaves the sides looking emptier than the
  /// measurement says they are. Half the margin brings the case in to hug the
  /// long row without the outermost caps overhanging it.
  static const double boardSidePad = 0.2;
  static const double boardPad = 0.5;

  /// How thick the case is.
  ///
  /// Deliberately slim. It was 0.18 once and read as a sheet of paper, which
  /// is why it went up to 0.75 — but that diagnosis was made while the
  /// geometry was still culling the top and bottom of every box, so what
  /// looked like a sheet was in fact a slab with no lid. With the faces
  /// drawing, a low profile reads as a low profile.
  static const double boardHeight = 0.2;

  /// Sideways offset per row.
  ///
  /// What makes it read as a keyboard rather than as a grid: real rows are
  /// not aligned, and the eye knows it.
  static const List<double> rowStagger = <double>[0, 0.15, 0.3, 0.1];

  /// The board is smaller than its own units suggest — it is an object in a
  /// hall, not furniture the visitor sits at.
  ///
  /// Sized to survive a narrow window. At 0.7 the board was 6.3 across and
  /// the camera sits 3.87 away, which frames it comfortably on a wide screen
  /// and cuts both ends off on a square one — a viewport of 1:1 shows only
  /// 4.92 units at that distance. Half scale is 4.5 and fits everywhere.
  static const double scale = 0.5;

  /// How high the board floats above the floor.
  ///
  /// High enough to read as floating rather than as standing on something
  /// just out of frame. At two-thirds of a unit it sat close enough to the
  /// ground that the eye supplied a plinth.
  static const double hoverHeight = 1.4;

  /// How far it rises and falls where it hangs, and how fast.
  ///
  /// The original gave it the same slow breath. A thing suspended in an empty
  /// room with no motion at all reads as a rendering of an object rather than
  /// an object; this is small enough to be noticed only on second look.
  static const double bobHeight = 0.08;
  static const double bobRate = 0.4;

  /// Where the board hangs, in design space.
  static Vector3 get anchor => Vector3(
    GalleryDimensions.kbX,
    GalleryDimensions.floorY + hoverHeight,
    GalleryDimensions.kbZ,
  );

  static int get columns =>
      GallerySkills.rows.map((r) => r.length).reduce((a, b) => a > b ? a : b);

  static int get rows => GallerySkills.rows.length;

  /// Width and depth of the case, before [scale].
  static double get boardWidth => columns * keyStep + boardSidePad * 2;
  static double get boardDepth => rows * keyStep + boardPad * 2;

  /// Every keycap, in board space.
  static List<KeyPlacement> keys() {
    final placed = <KeyPlacement>[];

    for (var row = 0; row < GallerySkills.rows.length; row++) {
      final skills = GallerySkills.rows[row];

      // Each row is centred on *its own* width, not the board's. The rows run
      // 8/7/6/5, so centring them all on the widest would leave every short
      // row flush left and the board looking like a mistake.
      final rowWidth = skills.length * keyStep;
      final startX = -rowWidth / 2 + keyStep / 2 + rowStagger[row];

      // Row zero is the far row and the last is nearest the visitor, so the
      // order the data reads in is the order they are met.
      final z = (rows / 2 - row - 0.5) * keyStep;

      for (var column = 0; column < skills.length; column++) {
        placed.add(
          KeyPlacement(
            skill: skills[column],
            row: row,
            column: column,
            position: Vector3(startX + column * keyStep, 0, z),
            extents: Vector3(capSize, keyHeight, capSize),
          ),
        );
      }
    }

    return placed;
  }

}
