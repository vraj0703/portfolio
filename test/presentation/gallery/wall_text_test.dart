import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/style/text_styles.dart';
import 'package:portfolio/presentation/gallery/wall_text.dart';

void main() {
  group('the cut', () {
    test('both edges are displaced by the same distance', () {
      final unit = WallText.normalise(WallText.lightFrom);

      // The lit edge and the shadowed one are the same letterform moved in
      // opposite directions. Different distances and the letter reads as
      // double-struck rather than carved — one copy visibly wider than the
      // other, which is a printing fault, not a groove.
      final lit = -unit * WallText.cutWidth;
      final shadowed = unit * WallText.cutWidth;

      expect(unit.distance, closeTo(1, 1e-9));
      expect(shadowed.distance, closeTo(WallText.cutWidth, 1e-9));
      // The equality that actually matters is between the two, not between
      // either one and the constant.
      expect(lit.distance, closeTo(shadowed.distance, 1e-12));
      expect(lit, Offset(-shadowed.dx, -shadowed.dy));
    });

    test('the light comes from above', () {
      // Negative y is up on a canvas. The eye reads a surface entirely from
      // which of its two edges is lit: put the light below and the same
      // texture reads as lettering standing proud of the wall.
      expect(WallText.lightFrom.dy, lessThan(0));
    });

    test('a direction of no length does not divide by zero', () {
      expect(WallText.normalise(Offset.zero), Offset.zero);
    });

    test('the cut is wider than its edges are soft', () {
      // Softer than it is wide and the two edges blur into one another,
      // which is a smudge rather than a groove.
      expect(WallText.cutWidth, greaterThan(WallText.edgeSoftness));
    });

    test('the occlusion reaches further than the cut but does not glow', () {
      // It darkens the stone around each letter. Bigger than the cut, or it
      // is just a thicker shadow edge; partial, or it is a plate.
      expect(WallText.occlusionRadius, greaterThan(WallText.cutWidth));
      expect(WallText.occlusionAlpha, greaterThan(0));
      expect(WallText.occlusionAlpha, lessThan(1));
    });
  });

  group('the two faces of the cut', () {
    test('are separated by far more than the wall ever was', () {
      double luminance(int argb) {
        final r = (argb >> 16) & 0xFF;
        final g = (argb >> 8) & 0xFF;
        final b = argb & 0xFF;
        return (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255;
      }

      final shadow = luminance(
        // ignore: deprecated_member_use
        DefaultAppTypography.wallCutShadow.value,
      );
      final light = luminance(
        // ignore: deprecated_member_use
        DefaultAppTypography.wallCutLight.value,
      );

      // The measurement this whole approach came from: the marble's own
      // albedo is 0.875, and the ink painted on it was 0.908 — a ratio of
      // 1.04:1 where text wants 4.5:1, before the room's lights were even
      // applied to the wall and not to the lettering. The cut does not
      // compete with the wall at all; it carries both of its own values.
      const marble = 0.875;
      expect(marble - shadow, greaterThan(0.5));
      expect(light, greaterThan(marble));
    });
  });
}
