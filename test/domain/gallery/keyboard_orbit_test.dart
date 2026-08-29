import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/keyboard_orbit.dart';

void main() {
  KeyboardOrbit fresh() => KeyboardOrbit(restElevation: 0.4);

  test('it starts at the doorway view', () {
    // Zero azimuth is where the walk in ends, so the orbit begins exactly
    // where the approach handed over.
    final orbit = fresh();
    expect(orbit.azimuth, 0);
    expect(orbit.elevation, orbit.restElevation);
  });

  test('dragging carries the visitor round the board', () {
    final orbit = fresh()..drag(100, 0);
    expect(orbit.azimuth, isNot(0));
  });

  test('they can walk the whole way round, with no far side', () {
    // Azimuth is unclamped in the original too: the board has a back, and
    // stopping the visitor from seeing it would be arbitrary.
    final orbit = fresh();
    for (var i = 0; i < 40; i++) {
      orbit.drag(100, 0);
    }
    expect(orbit.azimuth.abs(), greaterThan(6.28));
  });

  group('the elevation', () {
    test('cannot climb past its limits', () {
      // Carried from the original's polar clamp. Level with the board the
      // caps are edge-on; higher and it reads as a desk looked down on.
      final up = fresh();
      for (var i = 0; i < 50; i++) {
        up.drag(0, -200);
      }
      expect(up.elevation, KeyboardOrbit.minElevation);

      final down = fresh();
      for (var i = 0; i < 50; i++) {
        down.drag(0, 200);
      }
      expect(down.elevation, KeyboardOrbit.maxElevation);
    });

    test('answers a sideways drag far less than a vertical one', () {
      // Walking round has the whole circle; climbing has a narrow band, so
      // matching the rates would slam it into a limit on every drag.
      expect(KeyboardOrbit.climbSensitivity, lessThan(1));
    });
  });

  group('a flick', () {
    test('glides on after the visitor lets go', () {
      final orbit = fresh()..drag(120, 0);
      final released = orbit.azimuth;

      orbit.update(1 / 60);
      expect(orbit.azimuth.abs(), greaterThan(released.abs()));
    });

    test('comes to rest rather than drifting for ever', () {
      final orbit = fresh()..drag(120, 0);

      for (var i = 0; i < 240; i++) {
        orbit.update(1 / 60);
      }

      expect(orbit.isMoving, isFalse);
    });

    test('travels the same distance whatever the frame rate', () {
      // A fixed fraction per frame glides further on a faster machine, so the
      // same flick would behave differently on two displays.
      double glide(double dt, int steps) {
        final orbit = fresh()..drag(120, 0);
        final from = orbit.azimuth;
        for (var i = 0; i < steps; i++) {
          orbit.update(dt);
        }
        return orbit.azimuth - from;
      }

      expect(glide(1 / 60, 60), closeTo(glide(1 / 120, 120), 0.02));
    });

    test('stops at a tilt limit instead of pressing against it', () {
      final orbit = fresh();
      for (var i = 0; i < 50; i++) {
        orbit.drag(0, 200);
      }

      expect(orbit.elevation, KeyboardOrbit.maxElevation);
      orbit.update(1 / 60);
      expect(orbit.elevation, KeyboardOrbit.maxElevation);
    });
  });

  group('leaving', () {
    test('eases the visitor back to the doorway view', () {
      // Otherwise a reverse scroll walks them out of the hall sideways, still
      // facing the board from wherever they had wandered to, and they arrive
      // in the wing looking at the wrong wall.
      final orbit = fresh()..drag(300, 120);

      for (var i = 0; i < 240; i++) {
        orbit.settle(1 / 60);
      }

      expect(orbit.azimuth, closeTo(0, 1e-3));
      expect(orbit.elevation, closeTo(orbit.restElevation, 1e-3));
    });

    test('takes the short way round', () {
      // A visitor who has walked most of a circle should not be carried back
      // past everything they came round.
      final orbit = fresh();
      for (var i = 0; i < 12; i++) {
        orbit.drag(100, 0);
      }
      final walked = orbit.azimuth;
      expect(walked.abs(), greaterThan(3.2), reason: 'past the halfway point');

      orbit.settle(1 / 60);

      // Folded onto the nearest equivalent angle rather than unwound. Walking
      // 7.2 radians is a turn and a bit; the way home is the remaining 0.9,
      // not all 7.2 back past everything they came round. The sign does not
      // have to flip for that — a shade over a full circle is nearest by
      // carrying on the way they were already going.
      expect(orbit.azimuth.abs(), lessThan(walked.abs() / 2));
      expect(orbit.azimuth.abs(), lessThan(3.15));
    });
  });
}
