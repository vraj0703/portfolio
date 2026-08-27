/// Timing and geometry for the hero title sequence, carried over from the
/// previous site.
///
/// The whole stage is a choreography: the mark retreats to the corner, a beat
/// passes, the name resolves out of nothing, then the line beneath it
/// arrives. The pauses are as load-bearing as the animations — without them
/// the stage reads as three things happening at once.
abstract final class TitleConfig {
  /// Beat between the logo settling in its corner and the title starting.
  static const Duration entranceDelay = Duration(milliseconds: 1000);

  /// Further pause before the name begins resolving.
  static const Duration revealDelay = Duration(milliseconds: 1000);

  /// How long the name takes to fade and scale in.
  static const Duration primaryDuration = Duration(milliseconds: 3000);

  /// How long the secondary line takes once the name has landed.
  static const Duration secondaryDuration = Duration(milliseconds: 1200);

  /// The name drifts upward slightly after settling, like heat rising off it.
  ///
  /// Measured from when the name *starts resolving*, and it starts partway
  /// through — the drift overlaps the arrival rather than following it, so
  /// the name is never perfectly still.
  static const Duration driftDelay = Duration(milliseconds: 1000);
  static const Duration driftDuration = Duration(milliseconds: 2000);
  static const double driftY = -20;

  /// Vertical gap from the name to the line beneath it.
  static const double secondaryOffsetY = 48;

  /// The name grows from nothing.
  ///
  /// Zero, not "small": scaling up from 82% is a pop, and over a three-second
  /// window against a four-and-a-half-second swell it looks like the visual
  /// finished long before the sound did. Growing from nothing gives the
  /// arrival somewhere to travel.
  static const double primaryStartScale = 0;

  /// How long the animated backdrop takes to come up behind the title.
  ///
  /// Slow on purpose: it starts as the mark retreats and is still arriving
  /// when the name resolves, so the stage never has a moment where the
  /// background visibly "switches on".
  static const Duration backdropFadeIn = Duration(milliseconds: 2000);
}
