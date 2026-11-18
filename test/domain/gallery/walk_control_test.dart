import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/walk_control.dart';

void main() {
  group('the stick lives in the lower part of the screen', () {
    test('below the zone it holds the stick; above, a swipe', () {
      expect(WalkControl.holdsStick(900, 1000), isTrue);
      expect(WalkControl.holdsStick(200, 1000), isFalse);
      expect(WalkControl.holdsStick(10, 0), isFalse);
    });
  });

  group('the stick, two axes', () {
    const r = WalkControl.stickRadius;

    test('up and down, left and right, full at the radius', () {
      expect(WalkControl.stick(0, -r).y, closeTo(1, 1e-9));
      expect(WalkControl.stick(0, r).y, closeTo(-1, 1e-9));
      expect(WalkControl.stick(r, 0).x, closeTo(1, 1e-9));
      expect(WalkControl.stick(-r * 3, 0).x, closeTo(-1, 1e-9));
    });

    test('a resting thumb inside the round dead zone does nothing', () {
      final d = r * WalkControl.deadZone * 0.7;
      final s = WalkControl.stick(d, -d * 0.5);
      expect(s.x, 0);
      expect(s.y, 0);
    });

    test('the edge of the dead zone is a standstill, not a jump', () {
      final s = WalkControl.stick(0, -r * (WalkControl.deadZone + 0.01));
      expect(s.y, closeTo(0, 0.02));
    });
  });

  group('the rate follows the way of travel', () {
    const corridor = (x: 0.0, y: 1.0);
    const wall = (x: 1.0, y: 0.0);
    const up = (x: 0.0, y: 1.0);
    const down = (x: 0.0, y: -1.0);
    const right = (x: 1.0, y: 0.0);
    const left = (x: -1.0, y: 0.0);

    test('in the corridor up walks on, down walks back, sideways nothing', () {
      expect(WalkControl.rate(up, corridor, corridor), 1);
      expect(WalkControl.rate(down, corridor, corridor), -1);
      expect(WalkControl.rate(right, corridor, corridor), 0);
    });

    test('on the wall sideways glides along it, both ways', () {
      expect(WalkControl.rate(right, wall, wall), 1);
      expect(WalkControl.rate(left, wall, wall), -1);
      expect(WalkControl.rate(up, wall, wall), 0);
    });

    test('at the back wall: up holds, right glides, down walks back', () {
      // Ahead runs along the wall; behind runs up the corridor.
      expect(WalkControl.rate(up, wall, corridor), 0);
      expect(WalkControl.rate(right, wall, corridor), 1);
      expect(WalkControl.rate(down, wall, corridor), -1);
      expect(WalkControl.rate(left, wall, corridor), 0);
      // A diagonal up and right glides on round the corner.
      expect(
        WalkControl.rate((x: 0.7, y: 0.7), wall, corridor),
        closeTo(0.7, 1e-9),
      );
    });
  });

  group('sideways in the corridor picks a frame', () {
    const corridor = (x: 0.0, y: 1.0);
    const wall = (x: 1.0, y: 0.0);

    test('a firm, mostly sideways push picks that side', () {
      expect(
        WalkControl.side(
          (x: 0.9, y: 0.1),
          corridor,
          at: 1000,
          backWallStop: 3480,
        ),
        1,
      );
      expect(
        WalkControl.side(
          (x: -0.9, y: 0.0),
          corridor,
          at: 1000,
          backWallStop: 3480,
        ),
        -1,
      );
    });

    test('a soft push, a diagonal, or the wall picks nothing', () {
      expect(
        WalkControl.side(
          (x: 0.4, y: 0.0),
          corridor,
          at: 1000,
          backWallStop: 3480,
        ),
        0,
      );
      expect(
        WalkControl.side(
          (x: 0.7, y: 0.7),
          corridor,
          at: 1000,
          backWallStop: 3480,
        ),
        0,
      );
      expect(
        WalkControl.side((x: 0.9, y: 0.0), wall, at: 1000, backWallStop: 3480),
        0,
      );
    });
  });

  group('past the back wall the stick only travels', () {
    test(
      'sideways and up both carry on along the path; left and down back',
      () {
        const ahead = (x: 0.0, y: 1.0);
        expect(
          WalkControl.rate((x: 1, y: 0), ahead, ahead, pastCorner: true),
          1,
        );
        expect(
          WalkControl.rate((x: 0, y: 1), ahead, ahead, pastCorner: true),
          1,
        );
        expect(
          WalkControl.rate((x: -1, y: 0), ahead, ahead, pastCorner: true),
          -1,
        );
        expect(
          WalkControl.rate((x: 0.3, y: -0.8), ahead, ahead, pastCorner: true),
          -0.8,
        );
      },
    );
  });

  group('let go on the wall, the stick settles onto a whole card', () {
    const points = <double>[3480, 4100, 4570, 5040, 5510, 5980];

    test('the nearest card, or the back wall', () {
      expect(WalkControl.settleOn(4300, points), 4100);
      expect(WalkControl.settleOn(4400, points), 4570);
      expect(WalkControl.settleOn(3490, points), 3480);
      expect(WalkControl.settleOn(3480 - 20, points), 3480);
    });

    test('nothing in the corridor, or past the last card', () {
      expect(WalkControl.settleOn(3000, points), isNull);
      expect(WalkControl.settleOn(5980 + 300, points), isNull);
    });

    test('and it is quick', () {
      expect(WalkControl.settleSeconds, lessThan(0.3));
    });
  });

  group('the walk has inertia, like a body', () {
    const dt = 1 / 60;

    double timeTo(double from, double target, double fraction) {
      var speed = from;
      var t = 0.0;
      while ((speed - from).abs() < (target - from).abs() * fraction) {
        speed = WalkControl.speedTowards(speed, target, dt);
        t += dt;
      }
      return t;
    }

    test('it builds to the push in about the build time', () {
      final t = timeTo(0, WalkControl.maxSpeed, 0.95);
      expect(t, closeTo(WalkControl.buildSeconds, 3 * dt));
      expect(WalkControl.buildSeconds, inInclusiveRange(0.25, 0.4));
    });

    test('and coasts to rest on release, with friction, in about 0.3 s', () {
      var speed = WalkControl.maxSpeed;
      var t = 0.0;
      var distance = 0.0;
      while (speed > 0) {
        speed = WalkControl.speedTowards(speed, 0, dt);
        distance += speed * dt;
        t += dt;
      }
      expect(t, inInclusiveRange(0.25, 0.6));
      // A coast, not a stop: it carries on a little way.
      expect(distance, greaterThan(WalkControl.maxSpeed * 0.05));
    });

    test('harder is faster, and the rim is much faster than the middle', () {
      final quarter = WalkControl.targetSpeed(0.25, 0);
      final half = WalkControl.targetSpeed(0.5, 0);
      final threeQ = WalkControl.targetSpeed(0.75, 0);
      final full = WalkControl.targetSpeed(1, 0);
      expect(quarter, lessThan(half));
      expect(half, lessThan(threeQ));
      expect(threeQ, lessThan(full));
      expect(half / full, lessThan(0.3));
    });

    test('a held full push keeps building a little: the run', () {
      final start = WalkControl.targetSpeed(1, 0);
      final run = WalkControl.targetSpeed(1, WalkControl.runSeconds);
      expect(run / start, closeTo(WalkControl.runBoost, 1e-9));
      // A half push does not run.
      expect(WalkControl.targetSpeed(0.5, 3), WalkControl.targetSpeed(0.5, 0));
    });

    test('at the rim, with the run, the corridor takes about 5-6 s', () {
      final rim = WalkControl.targetSpeed(1, WalkControl.runSeconds);
      expect(WalkControl.corridorUnits / rim, inInclusiveRange(5.0, 6.0));
    });
  });

  group('what a touch does', () {
    const height = 800.0;

    test('the stick, low on the screen, in the corridor and in the hall', () {
      expect(WalkControl.roleFor(700, height, inHall: false), TouchRole.stick);
      // The hall too: the stick walks the approach to the board.
      expect(WalkControl.roleFor(700, height, inHall: true), TouchRole.stick);
    });

    test('above it, a swipe; in the hall, the board turns', () {
      expect(WalkControl.roleFor(200, height, inHall: false), TouchRole.swipe);
      expect(
        WalkControl.roleFor(200, height, inHall: true),
        TouchRole.boardDrag,
      );
    });
  });
}
