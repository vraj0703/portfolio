import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/config/logo_config.dart';
import 'package:portfolio/domain/config/mark_travel.dart';

void main() {
  const viewport = Size(1440, 900);

  MarkPlacement at(double journey) =>
      MarkTravel.at(journey, viewport: viewport);

  group('the two ends of the journey', () {
    test('at home it fills the middle of the screen', () {
      final home = at(0);

      expect(home.centre, const Offset(720, 450));
      expect(
        home.size.width,
        LogoConfig.logoMarkWidthFor(viewportWidth: 1440, viewportHeight: 900),
      );
    });

    test('parked, it is a header mark in the corner', () {
      final parked = at(1);

      // Anchored on its middle at both ends, so the corner has to account
      // for its own size — a mark centred on the margin hangs half off the
      // screen.
      expect(parked.bounds.left, closeTo(LogoConfig.exitMargin, 1e-9));
      expect(parked.bounds.top, closeTo(LogoConfig.exitMargin, 1e-9));
    });

    test('and a fifth the size', () {
      expect(
        at(1).size.width / at(0).size.width,
        closeTo(LogoConfig.exitScale, 1e-9),
      );
    });

    test('it keeps the artwork\'s proportions the whole way', () {
      for (final journey in <double>[0, 0.25, 0.5, 0.75, 1]) {
        final placement = at(journey);
        expect(
          placement.size.height / placement.size.width,
          closeTo(LogoConfig.markAspect, 1e-9),
          reason: 'stretched at $journey',
        );
      }
    });
  });

  group('the journey itself', () {
    test('runs one way, without doubling back', () {
      // The corridor plays this backwards to fly the mark home. A path that
      // wandered would read as the mark being flung rather than returning.
      var previous = at(0);

      for (var i = 1; i <= 20; i++) {
        final next = at(i / 20);
        expect(next.centre.dx, lessThan(previous.centre.dx));
        expect(next.centre.dy, lessThan(previous.centre.dy));
        expect(next.size.width, lessThan(previous.size.width));
        previous = next;
      }
    });

    test('is clamped at both ends', () {
      expect(at(-1).centre, at(0).centre);
      expect(at(2).centre, at(1).centre);
    });
  });

  group('the seam it exists to hide', () {
    test('agrees with the scene about where the corner is', () {
      // The title scene draws the mark through Flame and the corridor draws
      // it through Flutter, and they never share a frame. This is the
      // arithmetic the scene's own component does, written out — if the two
      // ever disagree the mark jumps at the handover, which is the one thing
      // it is there to prevent.
      final width = LogoConfig.logoMarkWidthFor(
        viewportWidth: viewport.width,
        viewportHeight: viewport.height,
      );
      final home = Size(width, width * LogoConfig.markAspect);
      final target = home * LogoConfig.exitScale;
      final corner = Offset(
        LogoConfig.exitMargin + target.width / 2,
        LogoConfig.exitMargin + target.height / 2,
      );

      expect(at(1).centre.dx, closeTo(corner.dx, 1e-9));
      expect(at(1).centre.dy, closeTo(corner.dy, 1e-9));
      expect(at(1).size.width, closeTo(target.width, 1e-9));
    });

    test('holds on a phone as well as a desktop', () {
      const phone = Size(390, 844);
      final parked = MarkTravel.at(1, viewport: phone);

      expect(parked.bounds.left, closeTo(LogoConfig.exitMargin, 1e-9));
      expect(parked.bounds.right, lessThan(phone.width));
      expect(parked.bounds.bottom, lessThan(phone.height));
    });
  });
}
