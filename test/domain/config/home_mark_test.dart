import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/config/logo_config.dart';

void main() {
  group('the mark at home on a phone (PORTFOLIO-29)', () {
    test('desktop and landscape: exactly the old rule', () {
      for (final (w, h) in <(double, double)>[
        (1280, 800),
        (1920, 1080),
        (915, 412), // a phone on its side
        (1024, 1366), // a tall tablet: wider than a phone
      ]) {
        expect(
          LogoConfig.homeMarkWidthFor(viewportWidth: w, viewportHeight: h),
          LogoConfig.logoMarkWidthFor(viewportWidth: w, viewportHeight: h),
          reason: '${w}x$h',
        );
      }
    });

    test('a portrait phone: larger by the boost, from 320 to 480 wide', () {
      for (var w = 320.0; w <= 480; w += 20) {
        final h = w * 2.2;
        final base = LogoConfig.logoMarkWidthFor(
          viewportWidth: w,
          viewportHeight: h,
        );
        expect(
          LogoConfig.homeMarkWidthFor(viewportWidth: w, viewportHeight: h),
          closeTo(base * (1 + LogoConfig.phoneMarkBoost), 1e-9),
        );
      }
    });

    test('"a little more", not dominant', () {
      expect(LogoConfig.phoneMarkBoost, inInclusiveRange(0, 0.35));
    });
  });

  group('the label\'s lines', () {
    test('desktop: the old values exactly', () {
      final l = LogoConfig.linesFor(
        viewportWidth: 1280,
        viewportHeight: 800,
        innerHalfWidth: 90,
      );
      expect(l.gap, LogoConfig.lineGap);
      expect(l.length, LogoConfig.lineLength);
      expect(l.travel, LogoConfig.lineTravel);
    });

    test('a portrait phone: never past the edge, 320 to 480 wide', () {
      for (var w = 320.0; w <= 480; w += 10) {
        for (final label in <double>[60, 90, 120]) {
          final l = LogoConfig.linesFor(
            viewportWidth: w,
            viewportHeight: w * 2.2,
            innerHalfWidth: label,
          );
          expect(l.length, greaterThanOrEqualTo(0));
          expect(l.travel, greaterThanOrEqualTo(0));
          // The outer end at full travel stays inside the margin.
          expect(
            l.gap + l.travel + l.length,
            lessThanOrEqualTo(w / 2 - LogoConfig.lineEdgeMargin + 1e-9),
            reason: 'w $w label $label',
          );
          // And clear of the label.
          expect(l.gap, greaterThan(label));
        }
      }
    });

    test('the 411 px phone: the lines are visible and move', () {
      final l = LogoConfig.linesFor(
        viewportWidth: 411,
        viewportHeight: 763,
        innerHalfWidth: 95,
      );
      expect(l.length, greaterThan(20));
      expect(l.travel, greaterThan(20));
    });
  });
}
