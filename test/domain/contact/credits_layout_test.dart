import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/contact/credits_layout.dart';

void main() {
  group('the credits dialog fits the screen (PORTFOLIO-31)', () {
    test('desktop 1440 x 900: a reading measure, wider than the old 460', () {
      final s = CreditsLayout.forScreen(1440, 900);
      expect(s.width, inInclusiveRange(560, 640));
      expect(s.width, greaterThan(460));
      expect(s.maxHeight, closeTo(900 * 0.85, 1e-9));
      expect(s.columns, 1);
      expect(s.paddingH, CreditsLayout.paddingH);
    });

    test('tablet 820 x 1180: between the phone and the desktop', () {
      final tablet = CreditsLayout.forScreen(820, 1180).width;
      expect(
        tablet,
        lessThanOrEqualTo(CreditsLayout.forScreen(1440, 900).width),
      );
      expect(tablet, greaterThan(460));
      expect(tablet, lessThanOrEqualTo(820 - 2 * CreditsLayout.tabletMargin));
    });

    test('phone 411 x 914: nearly the full width, 16 dp each side', () {
      final s = CreditsLayout.forScreen(411, 914);
      expect(s.width, 411 - 2 * 16);
      expect(s.insetLeft, 16);
      expect(s.insetRight, 16);
      expect(s.paddingH, CreditsLayout.phonePaddingH);
    });

    test('phone 320 x 568: still fits, at the dialog floor of 280', () {
      final s = CreditsLayout.forScreen(320, 568);
      expect(s.width, 288);
      expect(s.width, greaterThanOrEqualTo(280));
      expect(s.maxHeight, closeTo(568 * 0.85, 1e-9));
    });

    test('the safe area is kept clear: a notch on one side', () {
      final s = CreditsLayout.forScreen(
        411,
        914,
        safeLeft: 30,
        safeTop: 40,
        safeBottom: 20,
      );
      expect(s.insetLeft, 30 + 16);
      expect(s.width, 411 - 30 - 2 * 16);
      expect(s.insetTop, 40 + 16);
      expect(s.maxHeight, closeTo((914 - 40 - 20) * 0.85, 1e-9));
    });

    test('phone landscape 914 x 411: the height caps it, the body scrolls', () {
      final s = CreditsLayout.forScreen(914, 411);
      expect(s.width, lessThanOrEqualTo(914 - 2 * CreditsLayout.tabletMargin));
      expect(s.maxHeight, closeTo(411 * 0.85, 1e-9));
    });

    test('two columns only when asked for, and only on a wide desktop', () {
      expect(CreditsLayout.forScreen(1440, 900).columns, 1);
      expect(CreditsLayout.forScreen(1440, 900, columns: 2).columns, 2);
      expect(
        CreditsLayout.forScreen(1440, 900, columns: 2).width,
        CreditsLayout.twoColumnWidth,
      );
      expect(CreditsLayout.forScreen(1100, 800, columns: 2).columns, 1);
      expect(CreditsLayout.forScreen(411, 914, columns: 2).columns, 1);
    });

    test('the link target is a full 48 dp', () {
      expect(CreditsLayout.linkTarget, 48);
    });
  });
}
