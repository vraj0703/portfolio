import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/utils/scroll_motion.dart';

const double dt = 1 / 60;

/// Feeds [frames] frames of a wheel that clicks every [everyFrames] frames.
ScrollMotion wheel({
  required int everyFrames,
  double notch = 100,
  int frames = 120,
}) {
  final motion = ScrollMotion();
  for (var i = 0; i < frames; i++) {
    motion.sample(i % everyFrames == 0 ? notch : 0, dt);
  }
  return motion;
}

/// Feeds [frames] frames of continuous movement at [perFrame] units.
ScrollMotion drag({required double perFrame, int frames = 60}) {
  final motion = ScrollMotion();
  for (var i = 0; i < frames; i++) {
    motion.sample(perFrame, dt);
  }
  return motion;
}

void main() {
  group('a wheel is not a series of stops', () {
    test('a steady wheel reads as continuous movement', () {
      // The bug this class was written for. A wheel delivers one lump every
      // few frames and nothing in between, so a per-frame figure reads zero
      // on most frames — and anything asking "have they stopped?" was told
      // yes eight times out of nine while the visitor was plainly scrolling.
      final motion = wheel(everyFrames: 8);

      expect(motion.speed, greaterThan(300));
      expect(motion.speed, lessThan(900));
    });

    test('the faster the wheel, the higher it reads', () {
      expect(
        wheel(everyFrames: 2, notch: 120).speed,
        greaterThan(wheel(everyFrames: 4).speed),
      );
      expect(
        wheel(everyFrames: 4).speed,
        greaterThan(wheel(everyFrames: 8).speed),
      );
    });

    test('and a steady wheel is never mistaken for braking', () {
      // Between notches the smoothed speed sags, and that sag reads as
      // deceleration on most frames. It is the shape of the mouse, not the
      // visitor easing off — so the braking gate has to be deaf to it.
      final motion = ScrollMotion();
      var slowingFrames = 0;

      for (var i = 0; i < 240; i++) {
        motion.sample(i % 4 == 0 ? 100 : 0, dt);
        if (i > 30 && motion.isSlowing) slowingFrames++;
      }

      expect(slowingFrames, 0);
    });
  });

  group('the measurement the braking gate rests on', () {
    /// The most negative acceleration seen once [motion] has settled in.
    double deepestBrake(List<double> deltas) {
      final motion = ScrollMotion();
      var deepest = 0.0;

      for (var i = 0; i < deltas.length; i++) {
        motion.sample(deltas[i], dt);
        if (i > 20 && motion.acceleration < deepest) {
          deepest = motion.acceleration;
        }
      }
      return deepest;
    }

    test('a steady wheel ripples far less hard than a brake', () {
      // The whole reason `brakingRate` is a magnitude and not just a sign.
      // A wheel's spike train makes the smoothed speed sag between notches,
      // and that sag is deceleration by any test that only checks direction.
      final ripple = deepestBrake(
        List<double>.generate(120, (i) => i % 2 == 0 ? 120 : 0),
      );
      final brake = deepestBrake(
        List<double>.generate(60, (i) => i < 30 ? 150 : 0),
      );

      expect(ripple.abs(), lessThan(ScrollMotion.brakingRate));
      expect(brake.abs(), greaterThan(ScrollMotion.brakingRate));

      // Measured at roughly 800 against 12,000 when the threshold was set.
      // Should those ever come within a factor of two of each other, the
      // gate is guessing rather than deciding.
      expect(brake.abs(), greaterThan(ripple.abs() * 2));
    });
  });

  group('what counts as having arrived', () {
    test('an ordinary scroll has', () {
      // The case that used to miss. A detent exists to make sure the visitor
      // meets what it guards, so it must catch ordinary scrolling.
      expect(wheel(everyFrames: 8).hasArrived, isTrue);
      expect(wheel(everyFrames: 4).hasArrived, isTrue);
      expect(drag(perFrame: 40).hasArrived, isTrue);
    });

    test('a deliberate fling has not', () {
      // 150 a frame is 9000 a second, and held there. Somebody moving that
      // fast has decided where they are going.
      final fling = drag(perFrame: 150);
      expect(fling.speed.abs(), greaterThan(ScrollMotion.easingSpeed));
      expect(fling.hasArrived, isFalse);
    });

    test('but a fling easing off into something has', () {
      final motion = ScrollMotion();
      var arrived = false;

      // Fast, and coming off the gas the whole way.
      for (var i = 0; i < 60 && !arrived; i++) {
        motion.sample(300 * (1 - i / 60), dt);
        if (i > 5) arrived = motion.hasArrived;
      }

      expect(arrived, isTrue);
    });

    test('and standing still certainly has', () {
      final motion = drag(perFrame: 150);
      for (var i = 0; i < 60; i++) {
        motion.sample(0, dt);
      }

      // Decayed rather than cut off: a half-life of 0.14s leaves about a
      // hundred-and-thirtieth of 9000 after a second, which is a long way
      // below anything that counts as still moving.
      expect(motion.speed.abs(), lessThan(ScrollMotion.catchSpeed / 10));
      expect(motion.hasArrived, isTrue);
    });
  });

  group('direction is kept', () {
    test('scrolling back reads as negative, not as slowing', () {
      // `isSlowing` compares signs rather than testing the acceleration for
      // being negative — otherwise scrolling backwards faster and faster
      // would read as easing off.
      final motion = ScrollMotion();
      for (var i = 0; i < 60; i++) {
        motion.sample(-100, dt);
      }

      expect(motion.speed, lessThan(0));
      expect(motion.isSlowing, isFalse);
    });
  });

  test('reset puts it back the way it started', () {
    final motion = drag(perFrame: 150)..reset();

    expect(motion.speed, 0);
    expect(motion.acceleration, 0);
    expect(motion.isSlowing, isFalse);
  });
}
