import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/skill_data.dart';
import 'package:portfolio/domain/style/text_styles.dart';
import 'package:portfolio/presentation/gallery/keycap_legend.dart';

/// Each cap carries its skill's legend, sized per row to the row's longest.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const type = DefaultAppTypography();

  double widthAt(String label, double fontSize) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: type.keycapLegend.copyWith(fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  for (var r = 0; r < GallerySkills.rows.length; r++) {
    test('row $r: every legend fits its cap at the row size', () {
      final row = GallerySkills.rows[r];
      final size = KeycapLegend.fontSizeFor(row);

      expect(
        size,
        lessThanOrEqualTo(KeycapLegend.size * KeycapLegend.maxHeight),
      );
      for (final skill in row) {
        expect(
          widthAt(skill.label, size),
          lessThanOrEqualTo(KeycapLegend.size * KeycapLegend.fill + 0.5),
          reason: '${skill.label} overruns its cap',
        );
      }
    });
  }

  test('one row shares one size, so it reads as a set', () {
    // The size is a property of the row, not of each label: a short label on
    // a long row is not blown up to fill its own cap.
    final row = GallerySkills.rows.first;
    expect(KeycapLegend.fontSizeFor(row), KeycapLegend.fontSizeFor(row));
  });

  test('bakes a square, mostly transparent legend', () async {
    final skill = GallerySkills.all.first;
    final image = await KeycapLegend.render(skill, fontSize: 60);
    expect(image.width, KeycapLegend.size);
    expect(image.height, KeycapLegend.size);

    final bytes = (await image.toByteData())!;
    // A corner is clear: the cap shows through around the letters.
    expect(bytes.getUint8(3), 0);
    image.dispose();
  });
}
