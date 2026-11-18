import 'dart:math' as math;

import 'swipe_map.dart';

/// The corridor walked like a game corridor, on a touch screen.
///
/// Input never moves the visitor directly. A thumb stick sets a walking
/// rate, eased in and out, and every frame the walk advances the same
/// `ScrollDriver` the wheel and the old drag do, by rate times time, so the
/// path, the far wall's pause and the hall keep working untouched. A swipe
/// elsewhere on the screen is read by [SwipeMap] (it replaced the look drag).
/// Pure, so all of it is tested.
abstract final class WalkControl {
  /// The fraction of the screen's height below which a touch holds the
  /// stick; above it, a swipe ([SwipeMap]).
  static const double stickZone = 0.55;

  /// How far the thumb moves, in logical pixels, for a full push.
  static const double stickRadius = 56;

  /// The share of a full push that does nothing, so a resting thumb's
  /// tremor does not creep the visitor along.
  static const double deadZone = 0.12;

  // -- The tuning, in one place: each value is one line to change. -------

  /// Seconds a full push takes to walk the corridor end to end: a walking
  /// pace. 6 s read as running; 15 read as slow (Vishal, 2026-11-18).
  static const double corridorSeconds = 11;

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

  // -- The stick in two axes (Vishal, 2026-11-18: one continuous joystick).

  /// How far sideways (of a full push) the stick goes before the corridor
  /// turns to the nearest frame on that side, and how far back toward the
  /// middle it must come before it can pick again.
  static const double sideThreshold = 0.6;
  static const double sideRearm = 0.3;

  /// A sideways push must be this many times its up-or-down to pick a side,
  /// so a diagonal walk does not turn to a frame.
  static const double sideDominance = 1.5;

  /// The soft settle onto the nearest whole card after the stick is let go
  /// on the wall: how long it takes, and how far short of the back wall's
  /// stop still counts as at it.
  static const double settleSeconds = 0.25;
  static const double settleReach = 30;

  /// The stick's push from where the thumb landed, ([dx], [dy]) logical
  /// pixels: `x` right and `y` up, each -1..1, with a round dead zone so a
  /// resting thumb does nothing and a full push is 1 in any direction.
  static ({double x, double y}) stick(double dx, double dy) {
    final x = dx / stickRadius;
    final y = -dy / stickRadius;
    final length = math.sqrt(x * x + y * y);
    if (length <= deadZone + 1e-9) return (x: 0, y: 0);
    final scaled = (math.min(length, 1) - deadZone) / (1 - deadZone) / length;
    return (x: x * scaled, y: y * scaled);
  }

  /// The walking rate (-1..1, onward positive) for a stick push [s], with the
  /// path's way of travel on screen [ahead] of the visitor and [behind]
  /// them ([SwipeMap.travelAxis]: `y` into the screen, `x` across it).
  ///
  /// Onward is the push along the way ahead; back is the push against the
  /// way behind. They differ only at a corner, and that is the point: at
  /// the back wall the way ahead runs along the wall and the way behind runs
  /// up the corridor, so pushing up there holds (nothing ahead is up),
  /// pushing sideways glides along the wall, and pulling down walks back.
  static double rate(
    ({double x, double y}) s,
    ScreenAxis ahead,
    ScreenAxis behind, {
    bool pastCorner = false,
  }) {
    // Past the back wall (the wall, the alley, the hall) the path is the
    // only way to go, and both sideways and up keep the visitor travelling
    // along it: the larger component, right or up onward, left or down
    // back. No direction goes dead through the turn into the hall.
    if (pastCorner) return s.x.abs() >= s.y.abs() ? s.x : s.y;
    final onward = s.x * ahead.x + s.y * ahead.y;
    if (onward > 1e-9) return onward;
    final back = s.x * behind.x + s.y * behind.y;
    if (back < -1e-9) return back;
    return 0;
  }

  /// The side a push [s] turns to in the corridor: `1` right, `-1` left, or
  /// `0`. Only where the way [ahead] runs into the screen (on the wall,
  /// sideways is the way of travel), and only for a push well past
  /// [sideThreshold] and mostly sideways.
  static int side(
    ({double x, double y}) s,
    ScreenAxis ahead, {
    required double at,
    required double backWallStop,
  }) {
    // The corridor proper only: never on the wall, the alley or the hall,
    // where the path also runs into the screen and the nearest frame is the
    // corridor's last (Vishal, 2026-11-18: "it keeps jumping to the last
    // project").
    if (at >= backWallStop - 1) return 0;
    if (ahead.y.abs() <= ahead.x.abs()) return 0;
    if (s.x.abs() < sideThreshold) return 0;
    if (s.x.abs() < s.y.abs() * sideDominance) return 0;
    return s.x > 0 ? 1 : -1;
  }

  /// Where to settle after the stick is let go at [at] (scroll units): the
  /// nearest of the wall's whole-card stops [points] (the back wall's stop
  /// first), or null off the wall (the corridor, or on past the last card
  /// into the alley).
  static double? settleOn(double at, List<double> points) {
    if (points.isEmpty) return null;
    final spacing = points.length > 1
        ? points.last - points[points.length - 2]
        : 0;
    if (at < points.first - settleReach || at > points.last + spacing / 2) {
      return null;
    }
    var best = points.first;
    for (final point in points) {
      if ((point - at).abs() < (best - at).abs()) best = point;
    }
    return best;
  }

  /// What a touch at height [y] on a screen [height] tall does: the stick in
  /// the lower part everywhere, the hall included (it walks the approach to
  /// the board; mantr, 2026-11-18); above it, a swipe in the corridor and
  /// along the wall ([SwipeMap]), and the board's own drag in the hall.
  static TouchRole roleFor(double y, double height, {required bool inHall}) {
    if (holdsStick(y, height)) return TouchRole.stick;
    return inHall ? TouchRole.boardDrag : TouchRole.swipe;
  }

  /// Whether a touch at height [y] on a screen [height] tall holds the stick.
  static bool holdsStick(double y, double height) =>
      height > 0 && y >= height * stickZone;

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

  /// The scroll step a stick walk may take from [at] by [step]: all of it,
  /// unless walking on would carry it past [stop] (the back wall, where the
  /// statement is framed), in which case just enough to land on it. The
  /// stick stops there; letting go and pushing again walks on.
  static double stepToStop(double at, double step, double stop) {
    if (step > 0 && at < stop - 0.5 && at + step >= stop) return stop - at;
    return step;
  }
}

/// What a touch in the gallery does ([WalkControl.roleFor]).
enum TouchRole { stick, swipe, boardDrag }
