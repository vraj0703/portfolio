import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/config/title_timeline.dart';

void main() {
  group('TitleTimeline', () {
    test('nothing happens during the opening beat', () {
      // The pause after the mark parks is deliberate. If the name starts
      // resolving immediately the stage reads as one event rather than an
      // arrival.
      expect(TitleTimeline.primary(0), 0);
      expect(TitleTimeline.drift(0), 0);
    });

    test('the name resolves across its own window', () {
      final mid = (TitleTimeline.primaryStart + TitleTimeline.primaryEnd) / 2;

      expect(TitleTimeline.primary(TitleTimeline.primaryStart), 0);
      expect(TitleTimeline.primary(mid), greaterThan(0));
      expect(TitleTimeline.primary(mid), lessThan(1));
      expect(TitleTimeline.primary(TitleTimeline.primaryEnd), 1);
    });

    test('the line beneath is released only once the name has landed', () {
      // Overlapping them would read as a single block appearing.
      expect(TitleTimeline.secondaryStart, TitleTimeline.primaryEnd);
      expect(
        TitleTimeline.secondaryStart,
        greaterThan(TitleTimeline.primaryStart),
      );
    });

    test('the drift starts before the name has finished resolving', () {
      // The name should already be moving as it resolves, not settle and then
      // twitch.
      expect(TitleTimeline.driftStart, lessThan(TitleTimeline.primaryEnd));
      expect(TitleTimeline.driftStart, greaterThan(TitleTimeline.primaryStart));
    });

    test('every stage advances monotonically', () {
      var lastPrimary = 0.0;
      var lastDrift = 0.0;

      for (var t = 0.0; t <= TitleTimeline.secondaryStart + 1; t += 1 / 60) {
        final primary = TitleTimeline.primary(t);
        final drift = TitleTimeline.drift(t);

        expect(primary, greaterThanOrEqualTo(lastPrimary - 1e-9));
        expect(drift, greaterThanOrEqualTo(lastDrift - 1e-9));

        lastPrimary = primary;
        lastDrift = drift;
      }
    });

    test('every stage stays within bounds', () {
      for (var t = -1.0; t <= TitleTimeline.secondaryStart + 5; t += 1 / 30) {
        for (final value in <double>[
          TitleTimeline.primary(t),
          TitleTimeline.drift(t),
        ]) {
          expect(value, inInclusiveRange(0, 1), reason: 'at $t');
        }
      }
    });

    test('settles rather than running indefinitely', () {
      expect(TitleTimeline.primary(TitleTimeline.secondaryStart + 10), 1);
      expect(TitleTimeline.drift(TitleTimeline.secondaryStart + 10), 1);
    });
  });

  group('cue alignment', () {
    test('the stage opens on a pause, so cues cannot hang off state entry', () {
      // This is the trap: entering `titleLoading` and the name beginning to
      // resolve are seconds apart. A cue fired on the state change plays to
      // an empty screen and is fading by the time anything appears.
      expect(TitleTimeline.primaryStart, greaterThan(1));
      expect(TitleTimeline.primary(0), 0);
      expect(
        TitleTimeline.primary(TitleTimeline.primaryStart - 0.01),
        0,
        reason: 'still nothing on screen a frame before the name starts',
      );
    });

    test('the name is resolving the moment its cue is due', () {
      // Anything strictly after primaryStart should be visibly moving.
      expect(
        TitleTimeline.primary(TitleTimeline.primaryStart + 0.1),
        greaterThan(0),
      );
    });
  });
}
