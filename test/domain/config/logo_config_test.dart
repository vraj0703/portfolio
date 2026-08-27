import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/config/logo_config.dart';

/// Viewports the site actually gets opened at.
const viewports = <String, (double, double)>{
  'phone': (390, 844),
  'tablet portrait': (768, 1024),
  'small laptop': (1280, 720),
  'laptop': (1440, 900),
  'desktop': (1920, 1080),
  'short window': (1280, 500),
};

void main() {
  group('the mark is smaller on the loading screen than in the scene', () {
    for (final entry in viewports.entries) {
      final (w, h) = entry.value;

      test('at ${entry.key} (${w.toInt()}x${h.toInt()})', () {
        final loading = LogoConfig.loadingMarkWidthFor(
          viewportWidth: w,
          viewportHeight: h,
        );
        final scene = LogoConfig.logoMarkWidthFor(
          viewportWidth: w,
          viewportHeight: h,
        );

        expect(
          loading,
          lessThan(scene),
          reason: 'loading $loading vs scene $scene',
        );
      });
    }
  });

  group('the relationship is the same everywhere', () {
    test('the ratio holds at every viewport, not just wide ones', () {
      // The failure this replaced: two marks sharing a size factor and
      // differing only in their ceilings come out identical wherever neither
      // ceiling applies — which is most screens.
      for (final entry in viewports.entries) {
        final (w, h) = entry.value;

        final loading = LogoConfig.loadingMarkWidthFor(
          viewportWidth: w,
          viewportHeight: h,
        );
        final scene = LogoConfig.logoMarkWidthFor(
          viewportWidth: w,
          viewportHeight: h,
        );

        expect(
          loading / scene,
          closeTo(LogoConfig.loadingMarkScale, 1e-9),
          reason: 'at ${entry.key}',
        );
      }
    });

    test('both still obey the height clamp on a short window', () {
      // The clamp exists so the mark cannot crowd out the affordance beneath
      // it. Scaling must not let either mark grow back past it.
      const w = 1280.0;
      const h = 500.0;
      final limit = h * LogoConfig.markMaxHeightFactor / LogoConfig.markAspect;

      expect(
        LogoConfig.logoMarkWidthFor(viewportWidth: w, viewportHeight: h),
        lessThanOrEqualTo(limit + 1e-9),
      );
      expect(
        LogoConfig.loadingMarkWidthFor(viewportWidth: w, viewportHeight: h),
        lessThan(limit),
      );
    });

    test('the scene mark is capped on a very wide monitor', () {
      expect(
        LogoConfig.logoMarkWidthFor(viewportWidth: 5000, viewportHeight: 2000),
        LogoConfig.logoMarkMaxSize,
      );
    });

    test('the loading mark keeps the tuned size on a laptop', () {
      // 1280x720 is what the goldens are captured at, and what the size was
      // eyeballed against; the ratio was chosen to preserve it.
      expect(
        LogoConfig.loadingMarkWidthFor(
          viewportWidth: 1280,
          viewportHeight: 720,
        ),
        closeTo(300, 1),
      );
    });
  });
}
