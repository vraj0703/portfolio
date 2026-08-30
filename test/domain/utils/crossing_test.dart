import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/utils/crossing.dart';

void main() {
  group('Crossing', () {
    test('fires once, not on every frame past the mark', () {
      final crossing = Crossing(at: 0.5);

      expect(crossing.crossed(0.49), isFalse);
      expect(crossing.crossed(0.50), isTrue);

      // The bug this exists for: scroll position is not an event. It is
      // reported every frame, and the same number arrives sixty times a
      // second while the visitor holds still.
      for (var i = 0; i < 60; i++) {
        expect(crossing.crossed(0.7), isFalse);
      }
    });

    test('arms again when the visitor comes back', () {
      final crossing = Crossing(at: 0.5);

      expect(crossing.crossed(0.6), isTrue);
      expect(crossing.crossed(0.4), isFalse);
      // Genuinely passed twice, so genuinely heard twice. A plain latch goes
      // silent for the rest of the visit here.
      expect(crossing.crossed(0.6), isTrue);
    });

    test('does not chatter on a scroll resting at the mark', () {
      // Armed lower than it fires. Without the gap, a visitor holding the
      // scroll exactly on the threshold rearms and refires on alternate
      // frames as the value dithers around it.
      final crossing = Crossing(at: 0.5, rearmAt: 0.4);

      expect(crossing.crossed(0.5), isTrue);
      expect(crossing.crossed(0.49), isFalse);
      expect(crossing.crossed(0.5), isFalse);
      expect(crossing.crossed(0.45), isFalse);
      expect(crossing.crossed(0.5), isFalse);

      // Only once it has come back past the lower mark.
      expect(crossing.crossed(0.39), isFalse);
      expect(crossing.crossed(0.5), isTrue);
    });

    test('starts armed, so a value already past it fires', () {
      final crossing = Crossing(at: 0.5);
      expect(crossing.isArmed, isTrue);
      expect(crossing.crossed(0.9), isTrue);
      expect(crossing.isArmed, isFalse);
    });

    test('reset puts it back the way it started', () {
      final crossing = Crossing(at: 0.5)..crossed(0.9);
      expect(crossing.isArmed, isFalse);

      crossing.reset();
      expect(crossing.isArmed, isTrue);
      expect(crossing.crossed(0.9), isTrue);
    });
  });
}
