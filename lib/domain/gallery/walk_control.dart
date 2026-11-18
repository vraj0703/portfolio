import 'dart:math' as math;

/// The corridor walked like a game corridor, on a touch screen.
///
/// Input never moves the visitor directly. A thumb stick sets a walking
/// rate, eased in and out, and every frame the walk advances the same
/// `ScrollDriver` the wheel and the old drag do, by rate times time, so the
/// path, the far wall's pause and the hall keep working untouched. A drag
/// elsewhere on the screen turns the head, within a limit, and lets it ease
/// back to the path's heading on release. Pure, so all of it is tested.
abstract final class WalkControl {
  /// The fraction of the screen's height below which a touch holds the
  /// stick; above it, a drag looks around.
  static const double stickZone = 0.55;

  /// How far the thumb moves, in logical pixels, for a full push.
  static const double stickRadius = 56;

  /// The share of a full push that does nothing, so a resting thumb's
  /// tremor does not creep the visitor along.
  static const double deadZone = 0.12;

  /// Walking speed at a full push, in scroll units a second. The corridor's
  /// walk is about 3,500 units, so a full push walks it in about 12 s.
  static const double maxSpeed = 280;

  /// Seconds from standing to full speed, and from full speed to standing.
  static const double accelerateSeconds = 0.3;
  static const double stopSeconds = 0.4;

  /// How far the head turns either way, and how much a drag across the
  /// whole screen turns it.
  static const double maxLook = 35 * math.pi / 180;
  static const double lookPerScreenWidth = math.pi / 2;

  /// How quickly the head returns to the path's heading once let go.
  static const double lookReturnSeconds = 0.35;

  /// Whether a touch at height [y] on a screen [height] tall holds the stick.
  static bool holdsStick(double y, double height) =>
      height > 0 && y >= height * stickZone;

  /// The push, -1 (walk back) to 1 (walk forward), for a thumb that moved
  /// [dy] logical pixels from where it landed (negative is up). Up walks
  /// forward. Inside the dead zone, nothing; beyond it, rescaled so the
  /// edge of the dead zone is a standstill, not a jump.
  static double push(double dy) {
    final raw = (-dy / stickRadius).clamp(-1.0, 1.0);
    final size = raw.abs();
    if (size <= deadZone + 1e-9) return 0;
    return raw.sign * (size - deadZone) / (1 - deadZone);
  }

  /// The walking speed after [dt] seconds, moving from [current] toward the
  /// speed [push] asks for: no faster than full speed in [accelerateSeconds]
  /// when speeding up, or in [stopSeconds] when slowing or turning round.
  static double speedTowards(double current, double push, double dt) {
    final target = push.clamp(-1.0, 1.0) * maxSpeed;
    final speedingUp =
        target.abs() > current.abs() &&
        (current == 0 || target.sign == current.sign);
    final seconds = speedingUp ? accelerateSeconds : stopSeconds;
    final step = maxSpeed / seconds * dt;
    final gap = target - current;
    if (gap.abs() <= step) return target;
    return current + gap.sign * step;
  }

  /// The head's turn, in radians, for a drag [dx] logical pixels across a
  /// screen [width] wide, within [maxLook] either way. Dragging right turns
  /// the view right.
  static double look(double dx, double width) {
    if (width <= 0) return 0;
    return (dx / width * lookPerScreenWidth).clamp(-maxLook, maxLook);
  }

  /// The head's turn [dt] seconds after it was let go at [yaw], easing back
  /// to straight ahead.
  static double lookReturn(double yaw, double dt) {
    final next = yaw * math.exp(-dt / lookReturnSeconds);
    // Below a third of a degree it snaps home: an exponential never arrives.
    return next.abs() < 0.005 ? 0 : next;
  }
}
