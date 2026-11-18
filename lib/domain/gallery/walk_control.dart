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

  // -- The tuning, in one place: each value is one line to change. -------

  /// Seconds a full push takes to walk the corridor end to end: a walking
  /// pace (6 s at first read as running).
  static const double corridorSeconds = 15;

  /// The corridor's walk in scroll units: the gallery's scroll extent times
  /// the share of it that is the walk (`GalleryView.scrollExtent` 8000 x
  /// `GalleryCameraPath.walkFraction` 0.435; a test pins the product).
  static const double corridorUnits = 3480;

  /// Walking speed at a full push, in scroll units a second.
  static const double maxSpeed = corridorUnits / corridorSeconds;

  /// Seconds from standing to full speed, and from full speed to standing.
  /// Short to stop: letting go should stop the visitor, not let them glide.
  static const double accelerateSeconds = 0.3;
  static const double stopSeconds = 0.15;

  /// How tightly the camera follows while the stick drives, per second (the
  /// wheel and tap-to-frame keep their softer spring). High enough that the
  /// camera adds well under a tenth of a second to a stop.
  static const double stickChase = 60;

  /// How far the head turns either way, reached at a drag across the whole
  /// screen's width.
  static const double maxLook = 35 * math.pi / 180;

  /// Logical pixels a look drag may move before the head turns at all, so a
  /// tap or a resting finger does not nudge the view.
  static const double lookDeadZone = 8;

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
  /// screen [width] wide: nothing inside [lookDeadZone], then [maxLook] at a
  /// drag across the whole width, and no further. Dragging right turns the
  /// view right.
  static double look(double dx, double width) {
    if (width <= 0) return 0;
    final beyond = dx.abs() - lookDeadZone;
    if (beyond <= 0) return 0;
    return (dx.sign * beyond / width * maxLook).clamp(-maxLook, maxLook);
  }

  /// The head's turn [dt] seconds after it was let go at [yaw], easing back
  /// to straight ahead.
  static double lookReturn(double yaw, double dt) {
    final next = yaw * math.exp(-dt / lookReturnSeconds);
    // Below a third of a degree it snaps home: an exponential never arrives.
    return next.abs() < 0.005 ? 0 : next;
  }
}
