import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/config/pointer_config.dart';
import 'package:portfolio/domain/pointer/pointer_chooser.dart';
import 'package:portfolio/domain/pointer/pointer_path.dart';
import 'package:portfolio/domain/pointer/pointer_status.dart';

final Vector2 phoneScreen = Vector2(412, 915);
final Vector2 desk = Vector2(1280, 800);

Vector2 tilt(
  double beta,
  double gamma, {
  double angle = 0,
  Vector2? viewport,
  double travel = 1,
}) => TiltPointer.at(
  beta: beta,
  gamma: gamma,
  baseBeta: 40,
  baseGamma: 0,
  viewport: viewport ?? phoneScreen,
  screenAngle: angle,
  travel: travel,
);

void main() {
  group('tilt maps to a pointer around how the phone was held', () {
    test('held as it was: the centre', () {
      final p = tilt(40, 0);
      expect(p.x, closeTo(206, 1e-6));
      expect(p.y, closeTo(457.5, 1e-6));
    });

    test('like a marble: right edge down rolls right, top away rolls up', () {
      expect(tilt(40, 10).x, greaterThan(206));
      expect(tilt(40, -10).x, lessThan(206));
      expect(tilt(50, 0).y, lessThan(457.5));
      expect(tilt(30, 0).y, greaterThan(457.5));
    });

    test('the range reaches the edge, and no further', () {
      final r = PointerConfig.tiltRange;
      expect(tilt(40, r).x, closeTo(412, 1e-6));
      expect(tilt(40, r * 3).x, closeTo(412, 1e-6));
      expect(tilt(40 + r * 3, 0).y, closeTo(0, 1e-6));
      expect(tilt(40, -r / 2).x, closeTo(103, 1e-6));
    });

    test('a smaller travel stops short of the edge', () {
      final r = PointerConfig.tiltRange;
      expect(tilt(40, r, travel: 0.5).x, closeTo(206 + 103, 1e-6));
    });

    test('turned to landscape, the axes turn with the screen', () {
      final wide = Vector2(915, 412);
      // Turned 90: the device's top points left, so tipping its top away
      // rolls the pointer left on the screen.
      final p = tilt(50, 0, angle: 90, viewport: wide);
      expect(p.x, lessThan(457.5));
      expect(p.y, closeTo(206, 1e-6));
    });

    test('an angle across the +-180 seam is the short way round', () {
      final p = TiltPointer.at(
        beta: -175,
        gamma: 0,
        baseBeta: 175,
        baseGamma: 0,
        viewport: phoneScreen,
      );
      // 10 degrees on, not 350 back.
      expect(p.y, lessThan(457.5));
      expect(p.y, greaterThan(0));
    });
  });

  group('the idle drift', () {
    test('starts at the centre and is back there after one pass', () {
      final start = DriftPath.at(0, desk);
      expect(start.x, closeTo(640, 1e-6));
      expect(start.y, closeTo(400, 1e-6));
      final end = DriftPath.at(PointerConfig.driftPeriod, desk);
      expect(end.distanceTo(start), lessThan(1e-6));
    });

    test('one pass is calm: 12 to 20 s', () {
      expect(PointerConfig.driftPeriod, inInclusiveRange(12, 20));
    });

    test('never reaches an edge, and moves smoothly', () {
      var last = DriftPath.at(0, desk);
      var fastest = 0.0;
      for (var i = 1; i <= 1600; i++) {
        final p = DriftPath.at(i * 0.01, desk);
        expect(p.x, inExclusiveRange(0, 1280));
        expect(p.y, inExclusiveRange(0, 800));
        fastest = fastest > p.distanceTo(last) / 0.01
            ? fastest
            : p.distanceTo(last) / 0.01;
        last = p;
      }
      // Under half the screen's width a second: a light moving on its own.
      expect(fastest, lessThan(640));
    });

    test('a portrait phone travels less than a wide screen', () {
      expect(
        PointerConfig.travelFor(412, 915),
        lessThan(PointerConfig.travelFor(1280, 800)),
      );
    });
  });

  group('the chooser', () {
    test('phone: a finger, then the tilt, then the drift', () {
      final c = PointerChooser(phone: true)..sceneAppeared(0);
      expect(c.sourceAt(0), PointerSource.drift);
      c.tilted(40, 0, 0.1);
      expect(c.sourceAt(0.2), PointerSource.tilt);
      c.fingerDown(Vector2(10, 10));
      expect(c.sourceAt(0.3), PointerSource.touch);
      c.fingerUp();
      expect(c.sourceAt(0.4), PointerSource.tilt);
      // Left at rest (the ROG sent nothing more): the drift.
      expect(
        c.sourceAt(0.1 + PointerConfig.tiltRest + 0.01),
        PointerSource.drift,
      );
    });

    test('the first reading after a scene appears is the centre', () {
      final c = PointerChooser(phone: true)..sceneAppeared(0);
      c.tilted(70, 15, 0.1);
      final p = c.target(0.1 + PointerConfig.handover, phoneScreen);
      expect(p.distanceTo(phoneScreen / 2), lessThan(1e-6));
      // A new scene takes the angle it is held at then as its centre.
      c.sceneAppeared(1);
      expect(
        c
            .target(1 + PointerConfig.handover, phoneScreen)
            .distanceTo(phoneScreen / 2),
        lessThan(1e-6),
      );
      c.tilted(60, 5, 1.2);
      final p2 = c.target(1.2 + PointerConfig.handover, phoneScreen);
      expect(p2.x, lessThan(206));
      expect(p2.y, greaterThan(457.5));
    });

    test(
      'a phone at rest drifts; moved again, the tilt resumes from there',
      () {
        final c = PointerChooser(phone: true)..sceneAppeared(0);
        c.tilted(40, 0, 0);
        // Jitter under the threshold is rest, however often it is sent.
        for (var t = 0.5; t < 10; t += 0.5) {
          c.tilted(40.5, -0.4, t);
        }
        expect(c.sourceAt(10), PointerSource.drift);
        // Set down at a new angle, then picked up and tipped.
        c.tilted(10, 0, 20);
        expect(c.sourceAt(20), PointerSource.tilt);
        c.tilted(10, 0, 21);
        final p = c.target(21 + PointerConfig.handover, phoneScreen);
        expect(p.x, closeTo(206, 1e-6));
        c.tilted(10, 10, 22);
        expect(c.target(23, phoneScreen).x, greaterThan(206));
      },
    );

    test('desktop: the mouse, the drift after it rests, back at once', () {
      final c = PointerChooser(phone: false)..sceneAppeared(0);
      expect(c.sourceAt(1), PointerSource.still);
      expect(c.sourceAt(PointerConfig.mouseIdle + 0.1), PointerSource.drift);
      c.mouseMoved(Vector2(100, 100), 10);
      expect(c.sourceAt(10), PointerSource.mouse);
      expect(
        c.sourceAt(10 + PointerConfig.mouseIdle - 0.1),
        PointerSource.mouse,
      );
      expect(
        c.sourceAt(10 + PointerConfig.mouseIdle + 0.1),
        PointerSource.drift,
      );
      // The instant it moves, the mouse is the pointer, with no hand-over.
      c.target(20, desk);
      c.mouseMoved(Vector2(300, 200), 20.5);
      expect(c.target(20.5, desk), Vector2(300, 200));
    });

    test('a finger takes over at once; its release travels back', () {
      final c = PointerChooser(phone: true)..sceneAppeared(0);
      c.target(0, phoneScreen);
      c.fingerDown(Vector2(50, 60));
      expect(c.target(0.1, phoneScreen), Vector2(50, 60));
      c.fingerUp();
      final justAfter = c.target(0.11, phoneScreen);
      // Not a jump to the drift: still near where the finger left it.
      expect(justAfter.distanceTo(Vector2(50, 60)), lessThan(10));
      final later = c.target(0.1 + PointerConfig.handover + 0.01, phoneScreen);
      expect(
        later.distanceTo(
          DriftPath.at(
            PointerConfig.handover + 0.01 - 0.01,
            phoneScreen,
            travel: PointerConfig.travelFor(412, 915),
          ),
        ),
        lessThan(30),
      );
    });

    test('reduced motion: no drift, no tilt, the light at the centre', () {
      final c = PointerChooser(phone: true, reducedMotion: true)
        ..sceneAppeared(0);
      c.tilted(40, 0, 0.1);
      c.tilted(60, 20, 0.2);
      expect(c.sourceAt(0.2), PointerSource.still);
      expect(c.target(5, phoneScreen), phoneScreen / 2);
      // The visitor's own finger still lights it.
      c.fingerDown(Vector2(10, 10));
      expect(c.sourceAt(5), PointerSource.touch);

      final d = PointerChooser(phone: false, reducedMotion: true)
        ..sceneAppeared(0);
      expect(d.sourceAt(60), PointerSource.still);
      d.mouseMoved(Vector2(5, 5), 1);
      expect(d.sourceAt(60), PointerSource.mouse);
    });
  });

  group('analytics', () {
    test('pointer_source and tilt_permission, in their wire values', () {
      final s = PointerStatus()
        ..permission = TiltPermission.notAsked
        ..note(PointerSource.drift, 0.1);
      expect(s.now, {
        'pointer_source': 'drift',
        'tilt_permission': 'not_asked',
      });
      expect(TiltPermission.values.map((p) => p.wire), [
        'granted',
        'denied',
        'not_asked',
        'not_needed',
      ]);
    });

    test('a scene reports the source that drove it longest', () {
      final s = PointerStatus()
        ..note(PointerSource.tilt, 5)
        ..note(PointerSource.touch, 0.5);
      expect(s.scene()['pointer_source'], 'tilt');
      // And counts afresh for the next scene.
      s.note(PointerSource.drift, 1);
      expect(s.scene()['pointer_source'], 'drift');
    });
  });
}
