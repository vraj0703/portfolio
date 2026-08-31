import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/config/logo_config.dart';

void main() {
  double at(double t) => LogoConfig.markEntranceAt(t);

  group('the mark arrives rather than appears', () {
    test('it is barely there for the first tenth', () {
      // The regression this exists for. The curve was an ease-*out*, which
      // spends itself immediately: a tenth of the way through it was already
      // twenty-seven per cent on, so the mark read as appearing suddenly
      // however long the duration was set to.
      expect(at(0.1), lessThan(0.02));
      expect(at(0.2), lessThan(0.1));
    });

    test('and eases out at the far end too', () {
      // Symmetric. A gentle start that slams into full opacity is the same
      // fault seen from the other side.
      expect(1 - at(0.9), lessThan(0.02));
      expect(1 - at(0.8), lessThan(0.1));
    });

    test('is half on half way through', () {
      expect(at(0.5), closeTo(0.5, 1e-9));
    });

    test('runs from nothing to everything, only forwards', () {
      expect(at(0), 0);
      expect(at(1), 1);

      var previous = 0.0;
      for (var i = 1; i <= 20; i++) {
        final next = at(i / 20);
        expect(next, greaterThan(previous), reason: 'stalled at ${i / 20}');
        previous = next;
      }
    });

    test('is clamped at both ends', () {
      expect(at(-1), 0);
      expect(at(2), 1);
    });
  });

  group('the mark comes up with the work', () {
    /// How far on the mark is at [progress] through the load.
    double arrivedAt(double progress) =>
        LogoConfig.markEntranceAt(progress / LogoConfig.markRevealBy);

    test('hidden when the load has not started', () {
      expect(arrivedAt(0), 0);
    });

    test('fully on by the half way mark', () {
      expect(arrivedAt(LogoConfig.markRevealBy), 1);
    });

    test('and stays on for the rest, which belongs to the aura and flash', () {
      for (final progress in <double>[0.5, 0.7, 0.9, 1]) {
        expect(arrivedAt(progress), 1, reason: 'dimmed again at $progress');
      }
    });

    test('barely there through the first tenth of the load', () {
      // A tenth of the load is a fifth of the reveal, and the shape is
      // gentle at that end — the mark should be arriving, not arrived.
      expect(arrivedAt(0.1), lessThan(0.1));
    });

    test('and half on a quarter of the way in', () {
      expect(arrivedAt(LogoConfig.markRevealBy / 2), closeTo(0.5, 1e-9));
    });
  });

  group('the menu is given time to be read as typing', () {
    test('longer than the phrase it stands in for', () {
      // Twelve characters against nearer forty. Sharing a duration means the
      // row types more than three times as fast as "TAP TO ENTER" and reads
      // as a flicker.
      expect(
        LogoConfig.contactMenuDuration,
        greaterThan(LogoConfig.entranceDuration),
      );
    });
  });
}
