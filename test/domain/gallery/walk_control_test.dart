import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/walk_control.dart';

void main() {
  group('the stick lives in the lower part of the screen', () {
    test('below the zone it holds the stick; above, a drag looks around', () {
      expect(WalkControl.holdsStick(900, 1000), isTrue);
      expect(WalkControl.holdsStick(200, 1000), isFalse);
      expect(WalkControl.holdsStick(10, 0), isFalse);
    });
  });

  group('the push', () {
    test('up walks forward, down walks back, full at the radius', () {
      expect(WalkControl.push(-WalkControl.stickRadius), 1);
      expect(WalkControl.push(WalkControl.stickRadius), -1);
      expect(WalkControl.push(-WalkControl.stickRadius * 3), 1);
    });

    test('a resting thumb inside the dead zone does nothing', () {
      expect(
        WalkControl.push(-WalkControl.stickRadius * WalkControl.deadZone),
        0,
      );
      expect(WalkControl.push(2), 0);
    });

    test('and the edge of the dead zone is a standstill, not a jump', () {
      final justPast = -WalkControl.stickRadius * (WalkControl.deadZone + 0.01);
      expect(WalkControl.push(justPast), closeTo(0, 0.02));
    });
  });

  group('the walking speed eases in and out', () {
    test('full speed from standing takes the acceleration time', () {
      var speed = 0.0;
      const dt = 1 / 60;
      var t = 0.0;
      while (speed < WalkControl.maxSpeed) {
        speed = WalkControl.speedTowards(speed, 1, dt);
        t += dt;
      }
      expect(t, closeTo(WalkControl.accelerateSeconds, 2 * dt));
    });

    test('and letting go stops in the stopping time', () {
      var speed = WalkControl.maxSpeed;
      const dt = 1 / 60;
      var t = 0.0;
      while (speed > 0) {
        speed = WalkControl.speedTowards(speed, 0, dt);
        t += dt;
      }
      expect(t, closeTo(WalkControl.stopSeconds, 2 * dt));
    });

    test('turning round slows first, at the stopping rate', () {
      final next = WalkControl.speedTowards(WalkControl.maxSpeed, -1, 0.1);
      final stoppingStep = WalkControl.maxSpeed / WalkControl.stopSeconds * 0.1;
      expect(next, closeTo(WalkControl.maxSpeed - stoppingStep, 1e-9));
    });

    test('half a push walks at half speed', () {
      var speed = 0.0;
      for (var i = 0; i < 120; i++) {
        speed = WalkControl.speedTowards(speed, 0.5, 1 / 60);
      }
      expect(speed, closeTo(WalkControl.maxSpeed / 2, 1e-9));
    });
  });

  group('looking around', () {
    test('a drag turns the head, within the limit either way', () {
      expect(WalkControl.look(100, 400), greaterThan(0));
      expect(WalkControl.look(-100, 400), lessThan(0));
      expect(WalkControl.look(4000, 400), WalkControl.maxLook);
      expect(WalkControl.look(-4000, 400), -WalkControl.maxLook);
    });

    test('and eases back to straight ahead when let go', () {
      var yaw = WalkControl.maxLook;
      for (var i = 0; i < 120; i++) {
        yaw = WalkControl.lookReturn(yaw, 1 / 60);
      }
      expect(yaw, 0);
      expect(
        WalkControl.lookReturn(0.3, 1 / 60),
        allOf(lessThan(0.3), greaterThan(0)),
      );
    });
  });
}
