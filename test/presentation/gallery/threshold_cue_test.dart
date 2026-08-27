import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/presentation/gallery/threshold_cue.dart';

void main() {
  group('the beckon', () {
    test('escalates only while the visitor has not moved', () {
      // The escalation answers hesitation. Running it regardless would have
      // the cue growing more insistent at someone already walking.
      expect(ThresholdCue.idleAfterSeconds, greaterThan(0));
      expect(ThresholdCue.maxIdleGain, greaterThan(0));
    });

    test('is bounded, so it never reads as a fault', () {
      // An unbounded escalation eventually looks like something is broken
      // rather than like an invitation.
      expect(ThresholdCue.maxIdleGain, lessThanOrEqualTo(1));
    });

    test('waits long enough to be a response, not a nag', () {
      // Escalating immediately would fire at every visitor, including the
      // ones about to scroll anyway.
      expect(ThresholdCue.idleAfterSeconds, greaterThanOrEqualTo(3));
    });

    test('moves far enough to be seen, not so far it drifts off its mark', () {
      expect(ThresholdCue.beckonDepth, greaterThan(0.05));
      expect(ThresholdCue.beckonDepth, lessThan(0.5));
    });

    test('hangs inside the corridor, ahead of the visitor', () {
      // Behind the camera's start it would never be seen at all.
      expect(ThresholdCue.distanceIn, lessThan(0));
    });
  });
}
