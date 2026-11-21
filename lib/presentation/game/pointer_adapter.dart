import 'package:flame/components.dart';
import 'package:portfolio/data/pointer/motion_sensor.dart';
import 'package:portfolio/domain/pointer/pointer_chooser.dart';
import 'package:portfolio/domain/pointer/pointer_path.dart';
import 'package:portfolio/domain/pointer/pointer_status.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';

/// The one input adapter (PORTFOLIO-27), owned by `MyGame`: it hears the
/// mouse, the finger and the tilt, asks [PointerChooser] which drives, and
/// hands the answer to the game, which puts it in the `CursorTracker`. No
/// component reads a sensor, and nothing here smooths: the tracker does.
///
/// The tilt is listened to only on the logo and title scenes, where the
/// pointer lights anything, and the listener is removed on leaving them.
class PointerAdapter {
  PointerAdapter({
    required bool phone,
    MotionSensor? sensor,
    PointerStatus? status,
  }) : sensor = sensor ?? MotionSensor(),
       status = status ?? PointerStatus(),
       chooser = PointerChooser(phone: phone);

  final MotionSensor sensor;
  final PointerStatus status;
  final PointerChooser chooser;

  /// Game seconds: the chooser's clock, advanced by [update] only.
  double _now = 0;

  bool _active = false;

  /// Whether the pointer is lit by anything in [state]: the logo and title.
  static bool drivesIn(SceneState state) => state.maybeMap(
    logo: (_) => true,
    logoOverlayRemoving: (_) => true,
    titleLoading: (_) => true,
    title: (_) => true,
    active: (_) => true,
    orElse: () => false,
  );

  /// The scene changed. A scene that appears re-measures the tilt from how
  /// the phone is held now; the sensor runs only while it can matter.
  void scene(SceneState state) {
    final active = drivesIn(state);
    final appears = state.maybeMap(
      logo: (_) => true,
      titleLoading: (_) => true,
      orElse: () => false,
    );
    if (appears) chooser.sceneAppeared(_now);
    if (active == _active) return;
    _active = active;
    if (active) {
      chooser.reducedMotion = sensor.prefersReducedMotion;
      sensor.start(
        (beta, gamma, angle) =>
            chooser.tilted(beta, gamma, _now, screenAngle: angle),
      );
    } else {
      sensor.stop();
    }
  }

  /// The logo's tap, inside its own handler: the one moment iOS allows the
  /// motion prompt. Asked once; nothing happens on a browser that does not
  /// ask.
  void logoTapped() => sensor.requestPermission();

  void mouseMoved(Vector2 at) => chooser.mouseMoved(at, _now);
  void fingerDown(Vector2 at) => chooser.fingerDown(at);
  void fingerMoved(Vector2 at) => chooser.fingerMoved(at);
  void fingerUp() => chooser.fingerUp();
  void holdLastFinger() => chooser.holdLastFinger();
  void release() => chooser.release();

  /// Advances the clock by [dt] and answers where the pointer is on
  /// [viewport], or null where the pointer lights nothing (the gallery, the
  /// contact screen): the tracker is then left where it was.
  Vector2? update(double dt, Vector2 viewport) {
    _now += dt;
    status.permission = sensor.permission;
    if (!_active || viewport.x <= 0 || viewport.y <= 0) return null;
    final target = chooser.target(_now, viewport);
    status.note(chooser.source, dt);
    return target;
  }

  /// The source chosen on the last [update].
  PointerSource get source => chooser.source;

  void dispose() => sensor.stop();
}
