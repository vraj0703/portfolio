import 'dart:math' as math;

/// How the scroll is moving, as distinct from where it is.
///
/// Split out from [ScrollDriver] because "is the visitor still going?" turned
/// out to be a harder question than it looks, and answering it badly is what
/// made the pause at the far wall fire sometimes and not others.
///
/// The naive answer is the distance moved this frame divided by the frame's
/// length. That is fine for a touch drag, which delivers movement on every
/// frame, and useless for a wheel, which delivers it in lumps: one notch
/// arrives as a single large jump and the next eight frames are perfectly
/// still. Per-frame velocity therefore reads as a train of spikes separated
/// by zeros, and anything asking "have they stopped?" gets told yes eight
/// times out of nine — in the gaps *between* notches, while the visitor is
/// plainly still scrolling.
///
/// So both figures here are smoothed. [speed] decays toward zero rather than
/// dropping to it, which bridges the gaps in a wheel's output, and
/// [acceleration] is the rate that speed is changing at — the signal that
/// says the visitor is arriving somewhere rather than passing through it.
///
/// Signed throughout: direction matters. Slowing down is the *speed* falling
/// toward zero, which is not the same as the acceleration being negative
/// — that would mean "slowing" whenever the visitor scrolled backwards.
class ScrollMotion {
  /// How quickly the smoothed figures forget, as a half-life in seconds.
  ///
  /// Long enough to bridge the gap between two notches of a wheel, short
  /// enough that letting go is felt almost at once. At 60fps a notch every
  /// eight frames is a gap of 0.13s, so a half-life near that keeps a steady
  /// wheel reading as continuous motion.
  static const double halfLife = 0.14;

  /// A pause takes hold of anyone moving slower than this.
  ///
  /// Deliberately generous, and this is the whole tuning decision. A detent
  /// exists to make sure the visitor *meets* what it guards — so it should
  /// catch ordinary scrolling and let only a deliberate fling past. Set
  /// tight, it catches nobody except someone already nearly stopped, which
  /// is the version that fired sometimes and not others.
  ///
  /// Measured against real input patterns rather than guessed: a wheel notch
  /// is around a hundred units, and a smoothed speed comes out near 550 for
  /// a slow wheel, 1300 for a steady one and 3400 for a fast one. This sits
  /// above the steady wheel and below the fast one.
  static const double catchSpeed = 2500;

  /// And of anyone faster who is visibly easing off into it.
  ///
  /// The acceleration gate. Someone braking into the far wall means to stop
  /// there whatever speed they are still carrying, and catching them as they
  /// arrive is the difference between the room taking hold and the room
  /// twitching a moment too late.
  static const double easingSpeed = 6000;

  /// How hard they have to be easing off for it to count.
  ///
  /// Not simply "the acceleration opposes the speed". A wheel's output is a
  /// spike train, so even a perfectly steady wheel ripples: the smoothed
  /// speed climbs on each notch and sags in the gap, and the sag reads as
  /// deceleration on most frames. Measured, that ripple bottoms out around
  /// 800 units per second squared, while genuinely braking into something
  /// reaches nine to twelve thousand. This sits between the two, so the gate
  /// answers to a visitor slowing down and not to the shape of their mouse.
  static const double brakingRate = 3000;

  double _speed = 0;
  double _acceleration = 0;

  /// Signed, in units per second, smoothed.
  double get speed => _speed;

  /// Signed, in units per second squared, smoothed.
  double get acceleration => _acceleration;

  /// Whether the visitor is losing pace rather than gaining it.
  ///
  /// Compares the *sign* of the two rather than testing the acceleration for
  /// being negative: scrolling backwards has a negative speed, and a
  /// negative acceleration there means going backwards faster.
  bool get isSlowing =>
      _speed != 0 &&
      _acceleration.sign != _speed.sign &&
      _acceleration.abs() >= brakingRate;

  /// Whether the scroll has come to rest, or is close enough and slowing.
  ///
  /// The whole question this class exists for, kept here rather than at the
  /// call site so the two gates are read as one rule.
  bool get hasArrived =>
      _speed.abs() <= catchSpeed || (_speed.abs() <= easingSpeed && isSlowing);

  /// Reports [delta] units of movement over [dt] seconds.
  void sample(double delta, double dt) {
    if (dt <= 0) return;

    final instant = delta / dt;
    final keep = math.pow(0.5, dt / halfLife).toDouble();

    // The acceleration is taken from the change in the *smoothed* speed, not
    // from the raw one. Differentiating a spike train gives a larger spike
    // train, which would be a worse signal than the one it came from.
    final previous = _speed;
    _speed = _speed * keep + instant * (1 - keep);
    _acceleration = _acceleration * keep + ((_speed - previous) / dt) * (1 - keep);
  }

  void reset() {
    _speed = 0;
    _acceleration = 0;
  }
}
