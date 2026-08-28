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

    test('a long continuous scroll never leaks, however long it runs', () {
      // This is what a fixed delay could not fix: a deliberate, sustained
      // scroll simply outlasts any timeout and starts driving the new
      // surface while the visitor is still in the same gesture.
      for (var t = 20; t < 5000; t += 40) {
        expect(gate.accept(t), isFalse, reason: 'leaked at ${t}ms');
      }
    });

    test('a coasting trackpad decelerating into stillness is ignored', () {
      // The case a short threshold gets wrong. Momentum events do not arrive
      // evenly — they spread out as the flick dies away, so the tail of the
      // gesture eventually produces a gap that looks like a pause. Every one
      // of these still belongs to the stage the visitor left.
      var t = 20;
      for (var gap = 16; gap < quiet.inMilliseconds; gap += 12) {
        t += gap;
        expect(gate.accept(t), isFalse, reason: 'leaked at ${t}ms');
      }
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
