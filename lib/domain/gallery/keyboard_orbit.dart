import 'dart:math' as math;

/// Where the visitor has walked to around the skills board.
///
/// The camera orbits a board that stays put, as the original's
/// `OrbitControls` did — and that is the whole point rather than an
/// implementation detail. Turning the board instead moves nothing but the
/// board: the hall behind it sits dead still, and the eye reads a picture of
/// an object rather than an object in a room. Orbiting the camera slides the
/// walls past at their own rate, and that parallax is what makes the board
/// occupy somewhere.
///
/// The limits come straight across: the original clamped its polar angle to
/// keep the board a hero on a pedestal, never seen from overhead and never
/// from the floor.
///
/// Pure state, so the feel can be tested without a renderer: that a flick
/// glides rather than stopping dead, that it cannot be tipped past its
/// limits, and that it comes to rest rather than drifting for ever.
class KeyboardOrbit {
  KeyboardOrbit({required this.restElevation}) : _elevation = restElevation;

  /// The elevation the approach hands over at, so the orbit begins exactly
  /// where the walk in ended.
  final double restElevation;

  /// Radians per pixel dragged.
  ///
  /// About a third of a turn across a thousand pixels: enough that the board
  /// answers a short drag, little enough that it does not spin away under a
  /// flick.
  static const double sensitivity = 0.006;

  /// Vertical drags are damped against horizontal ones.
  ///
  /// Walking round the board is the natural move and has the whole circle to
  /// do it in; climbing has only a narrow band, so matching the two rates
  /// would slam the elevation into a limit on every sideways drag.
  static const double climbSensitivity = 0.4;

  /// How far above the board's own plane the visitor may get.
  ///
  /// Straight from the original's polar clamp — 0.34π to 0.48π from vertical,
  /// which is between about four and twenty-nine degrees above the board.
  /// Level with it the caps are edge-on; higher and it reads as a desk being
  /// looked down on rather than an exhibit.
  static const double minElevation = 0.063;
  static const double maxElevation = 0.503;

  /// How quickly a flick bleeds away, as a half-life in seconds.
  ///
  /// The original settled on roughly this: long enough that a flick glides,
  /// short enough that it does not feel like wading.
  static const double glideHalfLife = 0.14;

  /// Below this the board is treated as still, so it does not creep.
  ///
  /// In radians per second, like the velocities it is compared against.
  static const double stillness = 0.02;

  /// Pointer samples per second, assumed when turning a drag into a speed.
  ///
  /// A drag arrives as a series of steps with no time attached, so a step has
  /// to be read as "this far since the last sample" to become a rate. Getting
  /// it slightly wrong changes how hard a flick launches; leaving velocity as
  /// a per-step angle instead — which is what this replaced — changes how far
  /// the flick *travels* with the display's refresh rate, so the same gesture
  /// goes twice as far on a 120Hz screen.
  static const double pointerRate = 60;

  double _azimuth = 0;
  double _elevation;
  double _azimuthVelocity = 0;
  double _elevationVelocity = 0;

  /// How far round the board the visitor has walked. Zero is the doorway.
  double get azimuth => _azimuth;

  /// How far above the board's plane they are looking from.
  double get elevation => _elevation;

  /// Whether the board is still carrying a flick.
  bool get isMoving =>
      _azimuthVelocity.abs() > stillness ||
      _elevationVelocity.abs() > stillness;

  /// Walks the visitor round the board by a drag of [dx] by [dy] pixels.
  ///
  /// Dragging right carries them anticlockwise, so the board appears to turn
  /// to the right under the hand — the direction anyone expects from taking
  /// hold of a thing and pulling it.
  void drag(double dx, double dy) {
    final azimuthStep = -dx * sensitivity;
    final climbStep = dy * sensitivity * climbSensitivity;

    _azimuth += azimuthStep;
    _setElevation(_elevation + climbStep);

    // Taken from the drag itself rather than accumulated, so releasing
    // mid-drag carries the speed the hand was actually moving at — and
    // expressed as a rate, so the glide that follows is the same length
    // however often the display refreshes.
    _azimuthVelocity = azimuthStep * pointerRate;
    _elevationVelocity = climbStep * pointerRate;
  }

  /// Carries the flick on after the visitor lets go.
  void update(double dt) {
    if (dt <= 0) return;
    if (!isMoving) {
      _azimuthVelocity = 0;
      _elevationVelocity = 0;
      return;
    }

    final decay = math.pow(0.5, dt / glideHalfLife).toDouble();

    // Integrated in closed form rather than stepped. Decaying speed times a
    // timestep is an approximation whose error grows with the step, so the
    // same flick still travelled a couple of per cent further at 60fps than
    // at 120 — small, but it is exactly the kind of difference that makes a
    // gesture feel subtly wrong on one machine and right on another. For
    // exponential decay the distance covered over a step is exact, and the
    // total comes out identical however the time is sliced.
    final tau = glideHalfLife / math.ln2;
    _azimuth += _azimuthVelocity * tau * (1 - decay);
    _setElevation(_elevation + _elevationVelocity * tau * (1 - decay));

    _azimuthVelocity *= decay;
    _elevationVelocity *= decay;
  }

  /// Eases the visitor back to the doorway view.
  ///
  /// Called while they are leaving on a reverse scroll. Without it they walk
  /// back out of the hall sideways, still facing the board from wherever they
  /// had wandered to — and arrive in the wing looking at the wrong wall.
  void settle(double dt) {
    if (dt <= 0) return;
    final t = 1 - math.exp(-4 * dt);

    // The short way round, so a visitor who has walked most of a circle is
    // not carried back the long way past everything they came round.
    var shortest = _azimuth % (2 * math.pi);
    if (shortest > math.pi) shortest -= 2 * math.pi;
    if (shortest < -math.pi) shortest += 2 * math.pi;

    _azimuth = shortest * (1 - t);
    _elevation += (restElevation - _elevation) * t;
    _azimuthVelocity = 0;
    _elevationVelocity = 0;
  }

  void _setElevation(double value) {
    _elevation = value.clamp(minElevation, maxElevation);

    // A flick that runs into a limit stops there rather than pressing against
    // it for the rest of its glide.
    if (_elevation == minElevation || _elevation == maxElevation) {
      _elevationVelocity = 0;
    }
  }
}
