import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/presentation/gallery/scroll_gate.dart';

void main() {
  late ScrollGate gate;
  const quiet = ScrollGate.defaultQuietPeriod;

  setUp(() => gate = ScrollGate()..arrive(0));

  group('the gesture that carried the visitor here', () {
    test('a wheel still turning is ignored', () {
      // Events arriving hard on the heels of the handover belong to the
      // stage the visitor just left.
      expect(gate.accept(20), isFalse);
      expect(gate.accept(50), isFalse);
      expect(gate.accept(90), isFalse);
    });

    test('a continuous scroll is swallowed while the tail could still run', () {
      // The handover tail is the thing being disowned, and it does not last
      // anywhere near this long.
      for (var t = 20; t < ScrollGate.defaultMaximumHold.inMilliseconds;
          t += 40) {
        expect(gate.accept(t), isFalse, reason: 'leaked at \${t}ms');
      }
    });

    test('but it does not swallow for ever', () {
      // The bug this exists for: the gate opens only on a pause, and a
      // visitor who scrolls and sees nothing happen does not pause — they
      // scroll harder. Reaching the corridor a second time, the gallery was
      // unscrollable until they happened to click something, because a click
      // was the only thing that produced the stillness the gate wanted.
      //
      // A second past the handover there is no tail left, so anything still
      // arriving is a request to move rather than a leak.
      var t = 20;
      while (t < ScrollGate.defaultMaximumHold.inMilliseconds) {
        gate.accept(t);
        t += 40;
      }

      expect(gate.accept(t), isTrue);
    });

    test('the hold outlasts the quiet period it backs up', () {
      // A bound shorter than the pause it is a fallback for would arm first
      // every time and the pause would never be consulted.
      expect(
        ScrollGate.defaultMaximumHold,
        greaterThan(ScrollGate.defaultQuietPeriod),
      );
    });

    test('a coasting trackpad decelerating into stillness is ignored', () {
      // The case a short threshold gets wrong. Momentum events do not arrive
      // evenly — they spread out as the flick dies away, so the tail of the
      // gesture eventually produces a gap that looks like a pause. Every one
      // of these still belongs to the stage the visitor left.
      //
      // Bounded by the hold, and deliberately: a coast that ran five seconds
      // would not be momentum, it would be someone still scrolling, and the
      // gate is right to answer that.
      var t = 20;
      for (var gap = 16; gap < quiet.inMilliseconds; gap += 12) {
        if (t + gap >= ScrollGate.defaultMaximumHold.inMilliseconds) break;
        t += gap;
        expect(gate.accept(t), isFalse, reason: 'leaked at ${t}ms');
      }

      expect(t, greaterThan(400), reason: 'the tail should be a real length');
    });

  });

  group('a new gesture', () {
    test('is honoured once the input has gone quiet', () {
      expect(gate.accept(20), isFalse);
      expect(gate.accept(20 + quiet.inMilliseconds + 1), isTrue);
    });

    test('the quiet period outlasts a momentum tail', () {
      // Momentum events rarely spread beyond about a quarter second before
      // stopping altogether; the threshold has to sit clear of that.
      expect(quiet.inMilliseconds, greaterThan(250));
    });

    test('stays honoured for the rest of the visit', () {
      // Arming is one-way. Having recognised a deliberate gesture, the gate
      // must not start swallowing again during a natural pause in scrolling.
      gate
        ..accept(20)
        ..accept(20 + quiet.inMilliseconds + 1);

      expect(gate.isArmed, isTrue);
      expect(gate.accept(10000), isTrue);
      expect(gate.accept(10016), isTrue);
    });
  });

  group('arriving without scrolling', () {
    test('the first scroll is honoured immediately', () {
      // Reaching the gallery by clicking the arrow means there is no gesture
      // in flight, so there is nothing to wait through beyond the settle —
      // making the visitor scroll twice would be a bug of its own.
      final clicked = ScrollGate()..arrive(0);

      expect(clicked.accept(quiet.inMilliseconds + 1), isTrue);
    });
  });

  group('re-arrival', () {
    test('starts swallowing again', () {
      gate
        ..accept(20)
        ..accept(1000);
      expect(gate.isArmed, isTrue);

      gate.arrive(2000);
      expect(gate.isArmed, isFalse);
      expect(gate.accept(2020), isFalse);
    });
  });
}
