import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/config/title_config.dart';
import 'package:portfolio/domain/config/title_timeline.dart';

void main() {
  group('TitleTimeline', () {
    test('nothing happens during the opening beat', () {
      // The pause after the mark parks is deliberate. If the name starts
      // resolving immediately the stage reads as one event rather than an
      // arrival.
      expect(TitleTimeline.primaryFade(0), 0);
      expect(TitleTimeline.drift(0), 0);
    });

    test('the name resolves across its own window', () {
      final mid = (TitleTimeline.primaryStart + TitleTimeline.primaryEnd) / 2;

      expect(TitleTimeline.primaryFade(TitleTimeline.primaryStart), 0);
      expect(TitleTimeline.primaryFade(mid), greaterThan(0));
      expect(TitleTimeline.primaryFade(mid), lessThan(1));
      expect(TitleTimeline.primaryFade(TitleTimeline.primaryEnd), 1);
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
        final primary = TitleTimeline.primaryFade(t);
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
          TitleTimeline.primaryFade(t),
          TitleTimeline.drift(t),
        ]) {
          expect(value, inInclusiveRange(0, 1), reason: 'at $t');
        }
      }
    });

    test('settles rather than running indefinitely', () {
      expect(TitleTimeline.primaryFade(TitleTimeline.secondaryStart + 10), 1);
      expect(TitleTimeline.drift(TitleTimeline.secondaryStart + 10), 1);
    });
  });

  group('cue alignment', () {
    test('the stage opens on a pause, so cues cannot hang off state entry', () {
      // This is the trap: entering `titleLoading` and the name beginning to
      // resolve are seconds apart. A cue fired on the state change plays to
      // an empty screen and is fading by the time anything appears.
      expect(TitleTimeline.primaryStart, greaterThan(1));
      expect(TitleTimeline.primaryFade(0), 0);
      expect(
        TitleTimeline.primaryFade(TitleTimeline.primaryStart - 0.01),
        0,
        reason: 'still nothing on screen a frame before the name starts',
      );
    });

    test('the name is resolving the moment its cue is due', () {
      // Anything strictly after primaryStart should be visibly moving.
      expect(
        TitleTimeline.primaryFade(TitleTimeline.primaryStart + 0.1),
        greaterThan(0),
      );
    });
  });

  group('fade and scale are not the same curve', () {
    test('the name grows from nothing, not from nearly-there', () {
      // Scaling up from 82% is a pop. Over a three-second window against a
      // four-and-a-half-second swell it looks like the visual finished long
      // before the sound, which is the complaint that led here.
      expect(TitleConfig.primaryStartScale, 0);
    });

    test('the name becomes legible fast, then creeps to full size', () {
      // This is what carries the swell. The scale curve is deliberately not
      // the fade curve: it reaches most of its size quickly so the name is
      // readable, then keeps growing almost imperceptibly for the rest of the
      // window. A single shared curve completes visibly early and leaves four
      // and a half seconds of sound running over a static title.
      double at(double fraction) => TitleTimeline.primaryScale(
        TitleTimeline.primaryStart +
            (TitleTimeline.primaryEnd - TitleTimeline.primaryStart) * fraction,
      );

      expect(at(0.25), greaterThan(0.6), reason: 'legible early');
      expect(at(0.75), lessThan(1), reason: 'still has somewhere to go');

      final firstQuarter = at(0.25) - at(0);
      final lastQuarter = at(1) - at(0.75);
      expect(
        lastQuarter,
        lessThan(firstQuarter),
        reason: 'the tail must be a creep, not a second surge',
      );
    });

    test('both land together at the end', () {
      expect(TitleTimeline.primaryFade(TitleTimeline.primaryEnd), 1);
      expect(TitleTimeline.primaryScale(TitleTimeline.primaryEnd), 1);
    });

    test('the drift overlaps the arrival rather than following it', () {
      // Measured from when the name starts resolving, and beginning partway
      // through it, so the name is never perfectly still.
      expect(TitleTimeline.driftStart, greaterThan(TitleTimeline.primaryStart));
      expect(TitleTimeline.driftStart, lessThan(TitleTimeline.primaryEnd));
    });
  });
}
