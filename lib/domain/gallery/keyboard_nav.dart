import 'package:portfolio/domain/gallery/skill_data.dart';

/// Moving across the skills board with the arrow keys.
///
/// Pure, so it is tested without a board: which skill an arrow lands on from
/// [current]. The rows taper (8, 7, 6, 5), so moving up or down keeps the
/// column where it can and otherwise lands on the row's last key; moving off
/// either end of a row stops there rather than wrapping, because a board you
/// can fall off the edge of reads as one that skipped a key.
abstract final class KeyboardNav {
  /// The first key an arrow lands on when nothing is chosen yet.
  static Skill get start => GallerySkills.rows.first.first;

  /// The skill [dx] columns and [dy] rows from [current].
  static Skill move(Skill? current, {int dx = 0, int dy = 0}) {
    if (current == null) return start;

    final rows = GallerySkills.rows;
    var row = rows.indexWhere((r) => r.any((s) => s.id == current.id));
    if (row < 0) return start;
    var column = rows[row].indexWhere((s) => s.id == current.id);

    row = (row + dy).clamp(0, rows.length - 1);
    column = (column + dx).clamp(0, rows[row].length - 1);
    return rows[row][column];
  }
}
