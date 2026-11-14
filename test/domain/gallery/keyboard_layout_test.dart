import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/keyboard_layout.dart';
import 'package:portfolio/domain/gallery/skill_data.dart';

void main() {
  final keys = KeyboardLayout.keys();

  test('every skill gets a cap, and only one', () {
    final ids = keys.map((k) => k.skill.id).toSet();

    expect(keys, hasLength(GallerySkills.all.length));
    expect(ids, hasLength(GallerySkills.all.length), reason: 'a duplicate');
  });

  test('each row is centred on its own width, not the board\'s', () {
    // The rows run 8/7/6/5. Centring them all on the widest would leave every
    // short row flush left and the board looking like a mistake.
    for (var row = 0; row < KeyboardLayout.rows; row++) {
      final inRow = keys.where((k) => k.row == row).toList();
      final centre =
          inRow.map((k) => k.position.x).reduce((a, b) => a + b) / inRow.length;

      expect(
        centre,
        closeTo(KeyboardLayout.rowStagger[row], 1e-6),
        reason: 'row $row is off centre',
      );
    }
  });

  test('caps are evenly pitched along a row', () {
    for (var row = 0; row < KeyboardLayout.rows; row++) {
      final xs = keys.where((k) => k.row == row).map((k) => k.position.x)
          .toList();
      for (var i = 1; i < xs.length; i++) {
        expect(xs[i] - xs[i - 1], closeTo(KeyboardLayout.keyStep, 1e-6));
      }
    }
  });

  test('rows run from the far one to the nearest', () {
    // Row zero is the far row, so the order the data reads in is the order
    // the visitor meets them.
    for (var row = 1; row < KeyboardLayout.rows; row++) {
      final near = keys.firstWhere((k) => k.row == row).position.z;
      final far = keys.firstWhere((k) => k.row == row - 1).position.z;
      expect(near, lessThan(far));
    }
  });

  test('no cap hangs over the edge of the case', () {
    // A pitch that disagrees with the case leaves the outer keys floating.
    for (final key in keys) {
      expect(
        key.position.x.abs() + key.extents.x / 2,
        lessThan(KeyboardLayout.boardWidth / 2),
        reason: '${key.skill.id} overhangs the side',
      );
      expect(
        key.position.z.abs() + key.extents.z / 2,
        lessThan(KeyboardLayout.boardDepth / 2),
        reason: '${key.skill.id} overhangs the end',
      );
    }
  });

  test('the case is cut closer at the sides than at the ends', () {
    // The rows taper 8/7/6/5, so a margin generous enough to look right at
    // the ends leaves the sides reading as empty deck.
    expect(
      KeyboardLayout.boardSidePad,
      lessThan(KeyboardLayout.boardPad),
    );
  });

  test('caps leave a gap between them', () {
    // Cap smaller than pitch by exactly the gap, which is what makes the
    // gaps even rather than an artefact of two independent numbers.
    expect(KeyboardLayout.capSize, KeyboardLayout.keyUnit - KeyboardLayout.keyGap);
    expect(KeyboardLayout.capSize, lessThan(KeyboardLayout.keyStep));
  });


  test('it floats clear of the floor, inside its hall', () {
    final anchor = KeyboardLayout.anchor;
    expect(KeyboardLayout.hoverHeight, greaterThan(0));
    expect(anchor.y, greaterThan(-1.5));
  });
}
