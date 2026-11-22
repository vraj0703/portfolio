import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/domain/style/contrast.dart';

void main() {
  const colors = DefaultAppColors();

  // What the eye gets: the ink laid over the panel at its own alpha.
  double onPanel(Color ink) => Contrast.ratio(
    Color.alphaBlend(ink, colors.creditsPanel),
    colors.creditsPanel,
  );

  group('the credits read on their panel (PORTFOLIO-31)', () {
    test('the body, the title, the line under it and the close: 4.5:1', () {
      for (final (name, ink) in <(String, Color)>[
        ('body', colors.creditsBody),
        ('title', colors.creditsTitle),
        ('subtitle', colors.creditsSubtitle),
        ('close', colors.creditsAction),
      ]) {
        expect(onPanel(ink), greaterThanOrEqualTo(4.5), reason: name);
      }
    });

    test('the headings: at least 3:1, and lighter than the body', () {
      expect(onPanel(colors.creditsHeading), greaterThanOrEqualTo(3));
      expect(
        onPanel(colors.creditsHeading),
        lessThan(onPanel(colors.creditsBody)),
      );
    });

    test('the old brick did not: 1.96:1 for the body', () {
      final brick = const Color(0xFF9A482F).withValues(alpha: 0.85);
      expect(onPanel(brick), lessThan(3));
    });
  });
}
