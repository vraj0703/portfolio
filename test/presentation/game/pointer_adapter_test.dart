import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/data/pointer/motion_sensor.dart';
import 'package:portfolio/domain/pointer/pointer_path.dart';
import 'package:portfolio/domain/pointer/pointer_status.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/game/pointer_adapter.dart';

class FakeSensor implements MotionSensor {
  int starts = 0;
  int stops = 0;
  int asked = 0;
  bool listening = false;
  bool reduced = false;
  void Function(double, double, double)? onTilt;

  @override
  bool get prefersReducedMotion => reduced;

  @override
  TiltPermission permission = TiltPermission.notAsked;

  @override
  void requestPermission() => asked++;

  @override
  void start(void Function(double beta, double gamma, double angle) onTilt) {
    starts++;
    listening = true;
    this.onTilt = onTilt;
  }

  @override
  void stop() {
    if (listening) stops++;
    listening = false;
  }
}

void main() {
  final screen = Vector2(412, 915);

  group('the pointer adapter (PORTFOLIO-27)', () {
    test('listens to the tilt on the logo, title and contact only', () {
      final sensor = FakeSensor();
      final a = PointerAdapter(phone: true, sensor: sensor);
      a.scene(const SceneState.loading());
      expect(sensor.listening, isFalse);
      a.scene(const SceneState.logo());
      expect(sensor.listening, isTrue);
      a.scene(const SceneState.logoOverlayRemoving());
      a.scene(const SceneState.titleLoading());
      a.scene(const SceneState.title());
      a.scene(const SceneState.active());
      expect(sensor.starts, 1, reason: 'one listener across the two scenes');
      a.scene(const SceneState.gallery());
      expect(sensor.listening, isFalse);
      // The contact screen stands on the logo's light: it follows too.
      a.scene(const SceneState.contact());
      expect(sensor.listening, isTrue);
      a.scene(const SceneState.gallery());
      expect(sensor.listening, isFalse);
      a.scene(const SceneState.titleLoading());
      expect(sensor.listening, isTrue);
      a.dispose();
      expect(sensor.listening, isFalse);
    });

    test('drives the contact screen, mouse and all (regression, PR 26)', () {
      final a = PointerAdapter(phone: false, sensor: FakeSensor());
      a.scene(const SceneState.contact());
      a.mouseMoved(Vector2(60, 300));
      expect(a.update(1 / 60, Vector2(1280, 800)), Vector2(60, 300));
    });

    test('moves nothing where the pointer lights nothing', () {
      final a = PointerAdapter(phone: true, sensor: FakeSensor());
      a.scene(const SceneState.gallery());
      expect(a.update(1 / 60, screen), isNull);
      a.scene(const SceneState.logo());
      expect(a.update(1 / 60, screen), isNotNull);
    });

    test('drives the tracker from the tilt, and says so', () {
      final sensor = FakeSensor();
      final status = PointerStatus();
      final a = PointerAdapter(phone: true, sensor: sensor, status: status);
      a.scene(const SceneState.logo());
      a.update(0.1, screen);
      sensor.onTilt!(40, 0, 0);
      // The switch to the tilt travels from where the pointer was over the
      // hand-over; a fresh reading after it is where the tilt says.
      a.update(0.5, screen);
      sensor.onTilt!(40, 10, 0);
      final p = a.update(0.85, screen)!;
      expect(p.x, greaterThan(206));
      expect(status.source, PointerSource.tilt);
      expect(status.permission, TiltPermission.notAsked);
    });

    test('asks for the motion permission on the logo tap', () {
      final sensor = FakeSensor();
      PointerAdapter(phone: true, sensor: sensor).logoTapped();
      expect(sensor.asked, 1);
    });

    test('reduced motion: the centre, whatever the tilt', () {
      final sensor = FakeSensor()..reduced = true;
      final a = PointerAdapter(phone: true, sensor: sensor);
      a.scene(const SceneState.logo());
      sensor.onTilt!(40, 0, 0);
      sensor.onTilt!(60, 20, 0);
      expect(a.update(2, screen), screen / 2);
    });
  });
}
