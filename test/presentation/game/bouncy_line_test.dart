import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/config/logo_config.dart';
import 'package:portfolio/presentation/game/bouncy_line.dart';

/// Runs the simulation for [seconds] at a steady 60fps.
///
/// The spring is deliberately underdamped (zeta is roughly 0.35), so it
/// overshoots and rings before settling — give it real time, not a frame or
/// two, before asserting it has come to rest.
void settle(BouncyLine line, {double seconds = 5}) {
  const step = 1 / 60;
  for (var t = 0.0; t < seconds; t += step) {
    line.update(step);
  }
}

void main() {
  group('BouncyLine', () {
    test('starts at rest', () {
      final line = BouncyLine();
      expect(line.position, 0);
      expect(line.velocity, 0);
      expect(line.scale, 1);
    });

    test('travels toward its target', () {
      final line = BouncyLine()..target = 100;
      line.update(1 / 60);

      expect(line.position, greaterThan(0));
    });

    test('settles on the target and stops', () {
      final line = BouncyLine()..target = 120;
      settle(line);

      expect(line.position, closeTo(120, 0.5));
      expect(line.velocity.abs(), lessThan(0.5));
    });

    test('returns to rest when the target does', () {
      final line = BouncyLine()..target = 200;
      settle(line);

      line.target = 0;
      settle(line);

      expect(line.position, closeTo(0, 0.5));
    });

    test('stretches while moving and relaxes once settled', () {
      final line = BouncyLine()..target = 300;

      var peak = 1.0;
      for (var i = 0; i < 60; i++) {
        line.update(1 / 60);
        if (line.scale > peak) peak = line.scale;
      }
      expect(peak, greaterThan(1.05), reason: 'should stretch in motion');

      settle(line);
      expect(line.scale, closeTo(1, 0.05), reason: 'should relax at rest');
    });

    test('never stretches past the configured cap', () {
      final line = BouncyLine()..target = 100000;

      for (var i = 0; i < 600; i++) {
        line.update(1 / 60);
        expect(line.scale, lessThanOrEqualTo(LogoConfig.lineMaxScale + 1e-9));
      }
    });

    test('survives the long frame a backgrounded tab hands back', () {
      // Explicit Euler diverges when the step is large relative to the
      // spring's period. Without the clamp this flings off screen.
      final line = BouncyLine()..target = 100;
      line.update(5);

      expect(line.position.isFinite, isTrue);
      expect(line.position.abs(), lessThan(1000));

      settle(line);
      expect(line.position, closeTo(100, 0.5));
    });

    test('stays stable across a burst of long frames', () {
      final line = BouncyLine()..target = 150;
      for (var i = 0; i < 20; i++) {
        line.update(2);
      }

      // Clamping is the point: twenty 2-second frames advance only 20/30 of a
      // second of simulated time, so the line is still in flight rather than
      // settled. What matters is that it is bounded, not that it arrived —
      // the trade is that motion runs slow after a stall instead of blowing up.
      expect(line.position.isFinite, isTrue);
      expect(line.position.abs(), lessThan(500));

      settle(line);
      expect(line.position, closeTo(150, 0.5));
    });

    test('reset drops it back to rest immediately', () {
      final line = BouncyLine()..target = 250;
      settle(line, seconds: 0.2);

      line.reset();

      expect(line.position, 0);
      expect(line.target, 0);
      expect(line.velocity, 0);
      expect(line.scale, 1);
    });
  });
}
