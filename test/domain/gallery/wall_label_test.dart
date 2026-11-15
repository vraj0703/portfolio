import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/piece_art.dart';
import 'package:portfolio/domain/gallery/project_data.dart';
import 'package:portfolio/domain/gallery/wall_label.dart';

/// The wall label's rule: five things, the same on every piece, and an
/// empty field left off rather than invented.
void main() {
  Project byId(String id) => GalleryProjects.all.firstWhere((p) => p.id == id);

  test('every label follows the rule: eight words, three tags at most', () {
    for (final p in GalleryProjects.all) {
      final label = WallLabel.of(p);
      expect(
        label.lineWords,
        lessThanOrEqualTo(WallLabel.maxLineWords),
        reason: '${p.id}: "${p.line}"',
      );
      expect(
        p.tags.length,
        lessThanOrEqualTo(WallLabel.maxTags),
        reason: p.id,
      );
      expect(label.followsRule, isTrue, reason: p.id);
    }
  });

  test('the rule counts words, not characters', () {
    const long = Project(
      id: 'x',
      title: 'x',
      line: 'one two three four five six seven eight nine',
      url: '',
      accent: Color(0xFF000000),
      art: PieceArt.mesh,
      tags: <String>['a', 'b', 'c', 'd'],
    );
    expect(WallLabel.of(long).lineWords, 9);
    expect(WallLabel.of(long).followsRule, isFalse);
  });

  test('a full label carries all five, in order', () {
    expect(WallLabel.of(byId('tantr')).rows, <LabelRow>[
      LabelRow.name,
      LabelRow.line,
      LabelRow.figure,
      LabelRow.tags,
      LabelRow.years,
    ]);
  });

  test('an empty field is left off, not invented', () {
    // Tags for Twin Health and FieldAssist / PayU, and years for
    // Publications, are not known yet (art.py leaves them empty).
    expect(WallLabel.of(byId('twin-health')).rows, isNot(contains(LabelRow.tags)));
    expect(
      WallLabel.of(byId('fieldassist-payu')).rows,
      isNot(contains(LabelRow.tags)),
    );
    expect(
      WallLabel.of(byId('publications')).rows,
      isNot(contains(LabelRow.years)),
    );
  });

  test('a piece in preparation says so, and nothing it cannot back', () {
    for (final id in <String>['school-college', 'creative-works']) {
      expect(WallLabel.of(byId(id)).rows, <LabelRow>[
        LabelRow.name,
        LabelRow.line,
      ], reason: id);
    }
  });
}
