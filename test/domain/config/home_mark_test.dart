import 'dart:io';

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

    test("Vishal's pick: +50 %", () {
      expect(LogoConfig.phoneMarkBoost, 0.5);
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

  group('the label stops growing before its lines get too short', () {
    test('320 to 480 wide: the lines keep their minimum', () {
      for (var w = 320.0; w <= 480; w += 10) {
        for (final half in <double>[70, 95, 120]) {
          final scale = LogoConfig.labelScaleFor(
            viewportWidth: w,
            viewportHeight: w * 2.1,
            labelHalfWidth: half,
          );
          expect(scale, greaterThanOrEqualTo(1));
          expect(
            scale,
            lessThanOrEqualTo(LogoConfig.homeScaleFor(w, w * 2.1) + 1e-9),
          );
          final l = LogoConfig.linesFor(
            viewportWidth: w,
            viewportHeight: w * 2.1,
            innerHalfWidth: half * scale,
          );
          if (scale > 1) {
            expect(
              l.length,
              greaterThanOrEqualTo(LogoConfig.minLineLength - 1e-9),
              reason: 'w $w label $half',
            );
          }
        }
      }
    });

    test('desktop: the label is never scaled', () {
      expect(
        LogoConfig.labelScaleFor(
          viewportWidth: 1280,
          viewportHeight: 800,
          labelHalfWidth: 95,
        ),
        1,
      );
    });

    test('the light grows with the mark: the shader reads the factor', () {
      final frag = File('assets/shaders/god_rays.frag').readAsStringSync();
      expect(frag, contains('uniform float uLightScale;'));
      expect(frag, contains('distToLight / (uSize.y * uLightScale)'));
    });
  });
}
