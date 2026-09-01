import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/keyboard_layout.dart';

/// Walks the heading forward the way a render loop would.
double driftFor({
  required double reveal,
  required double seconds,
  double from = 0,
  double startAt = 0,
  double step = 1 / 60,
}) {
  var heading = from;
  for (var t = 0.0; t < seconds; t += step) {
    heading = KeyboardLayout.headingAfter(
      heading: heading,
      reveal: reveal,
      elapsed: startAt + t,
      dt: step,
    );
  }
  return heading;
}

void main() {
  group('the board has a life of its own on the way up', () {
    test('it turns while it is still low', () {
      // The failure this exists for: the board used to rise at a fixed
      // heading with its pose read straight off the scroll, so it was a
      // panel being lifted by the visitor's wheel rather than an object they
      // were walking towards.
      final turned = driftFor(reveal: 0.4, seconds: 2);

      expect(
        turned.abs(),
        greaterThan(0.05),
        reason: 'it rose without turning at all',
      );
    });

    test('and goes on turning rather than reaching a heading and stopping', () {
      // The target keeps advancing while the board is low, so the damping
      // never catches it. A target that stood still would be a board that
      // turned once and then held, which is a different thing entirely.
      final early = driftFor(reveal: 0.4, seconds: 2);
      final later = driftFor(reveal: 0.4, seconds: 6);

      expect(later, isNot(closeTo(early, 0.01)));
    });
  });

  group('and finds its heading once it is nearly there', () {
    test('it closes on rest', () {
      final settled = driftFor(reveal: 1, seconds: 3, from: 1.2);

      expect(
        settled.abs(),
        lessThan(0.01),
        reason: 'it never found its resting heading',
      );
    });

    test('from wherever the wandering left it', () {
      for (final from in <double>[0.3, 1.5, 3.0, -2.2, 5.9]) {
        final settled = driftFor(reveal: 1, seconds: 3, from: from);
        expect(
          settled.abs() % (math.pi * 2),
          anyOf(lessThan(0.01), greaterThan(math.pi * 2 - 0.01)),
          reason: 'starting at $from it settled somewhere other than rest',
        );
      }
    });

    test('and takes the short way to get there', () {
      // Just short of a full turn, rest is a hair *forwards*, not most of a
      // revolution backwards. Without the wrap it unwinds the long way every
      // time the wandering crosses its own start.
      const nearlyRound = math.pi * 2 - 0.2;
      final next = KeyboardLayout.headingAfter(
        heading: nearlyRound,
        reveal: 1,
        elapsed: 0,
        dt: 1 / 60,
      );

      expect(
        next,
        greaterThan(nearlyRound),
        reason: 'it turned back through a whole revolution to reach rest',
      );
    });
  });

  group('edges', () {
    test('a frame of no length moves nothing', () {
      // `dt` is zero on the first frame of a resumed loop, and a damping
      // step that moved anything then would jump the board.
      expect(
        KeyboardLayout.headingAfter(
          heading: 1.1,
          reveal: 1,
          elapsed: 5,
          dt: 0,
        ),
        1.1,
      );
    });

    test('the settle point is before the top of the rise', () {
      // It has to stop wandering *before* the visitor arrives, or the board
      // is still turning under a camera that has come to rest.
      expect(KeyboardLayout.settleAt, lessThan(1));
      expect(KeyboardLayout.settleAt, greaterThan(0.5));
    });
  });
}
