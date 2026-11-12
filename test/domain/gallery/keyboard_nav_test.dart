import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/keyboard_nav.dart';
import 'package:portfolio/domain/gallery/skill_data.dart';

void main() {
  final rows = GallerySkills.rows;

  test('the first arrow lands on the first key', () {
    expect(KeyboardNav.move(null, dx: 1), rows.first.first);
  });

  test('left and right walk a row and stop at its ends', () {
    expect(KeyboardNav.move(rows[0][0], dx: 1), rows[0][1]);
    expect(KeyboardNav.move(rows[0][0], dx: -1), rows[0][0]);
    expect(KeyboardNav.move(rows[0].last, dx: 1), rows[0].last);
  });

  test('up and down keep the column, and stop at the top and bottom', () {
    expect(KeyboardNav.move(rows[0][2], dy: 1), rows[1][2]);
    expect(KeyboardNav.move(rows[0][2], dy: -1), rows[0][2]);
    expect(KeyboardNav.move(rows.last[0], dy: 1), rows.last[0]);
  });

  test('down from a column the shorter row lacks lands on its last key', () {
    // Row 0 has 8 keys, row 1 has 7: the eighth column has nowhere to go
    // but the end of the row below.
    expect(KeyboardNav.move(rows[0][7], dy: 1), rows[1].last);
  });

  test('every key is reachable from the start', () {
    final seen = <String>{};
    for (var r = 0; r < rows.length; r++) {
      for (var c = 0; c < rows[r].length; c++) {
        var at = KeyboardNav.start;
        for (var i = 0; i < r; i++) {
          at = KeyboardNav.move(at, dy: 1);
        }
        at = KeyboardNav.move(at, dx: -10);
        for (var i = 0; i < c; i++) {
          at = KeyboardNav.move(at, dx: 1);
        }
        seen.add(at.id);
      }
    }
    expect(seen, hasLength(GallerySkills.all.length));
  });

  test('every key names itself in full for the caption', () {
    for (final skill in GallerySkills.all) {
      expect(skill.name, isNotEmpty, reason: skill.id);
      expect(skill.name.length, greaterThanOrEqualTo(skill.label.length));
    }
  });
}
