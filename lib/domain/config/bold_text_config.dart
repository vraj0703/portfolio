/// The scroll-driven bold-text sequence.
///
/// The whole stage is one shader parameter: everything the user sees — the
/// text arriving, the shine sweeping it, the starfield streaming outward, the
/// final flash — is a function of how far they have scrolled. That is what
/// lets the same sequence be driven by a wheel, a trackpad, or a click on the
/// arrow, without three separate animations to keep in step.
abstract final class BoldTextConfig {
  /// Total scrollable distance for the stage.
  static const double extent = 3000;

  /// Scroll distance mapped to the shader's full `0..1`.
  ///
  /// Shorter than [extent] on purpose: the sequence finishes slightly before
  /// the scroll does, so the last stretch is dead travel confirming the user
  /// meant to leave rather than an abrupt cut.
  static const double progressExtent = 2800;

  /// Where the sequence rests.
  ///
  /// Two pauses, which is what the arrow steps between: the start, and the
  /// point where the text is fully resolved and legible. The second sits in
  /// the shader's settled window (0.45–0.6 of progress), so the pause lands
  /// on the text at rest rather than mid-animation.
  static const List<double> snapPoints = <double>[0, 1500];

  /// How close the scroll has to be to a pause for it to take hold.
  static const double snapRadius = 500;

  /// Below this speed the scroll is considered to have stopped, and a nearby
  /// pause may claim it. Snapping under the user's finger feels like a fight.
  static const double snapVelocityThreshold = 40;

  /// How quickly the visible offset chases the target.
  static const double inertia = 8;

  /// Spring used to settle onto a pause.
  static const double snapStiffness = 120;
  static const double snapDamping = 20;

  /// Long frames are clamped, as everywhere else in the scene — an unclamped
  /// spring integrated over a stalled frame diverges.
  static const double maxStep = 1 / 30;

  /* -- What the scroll drives ------------------------------------------ */

  /// The title finishes leaving by this offset, and has fully faded by
  /// [titleFadeEnd] — earlier, so it is gone before it reaches the top.
  static const double titleParallaxExit = 800;
  static const double titleFadeEnd = 500;

  /// How far the title travels upward as it goes.
  static const double titleExitY = -1000;

  /// Where the final flash begins, and everything on the stage clears.
  static const double splashStart = 0.9;

  /// How much of the scroll cue is shown at a given sequence [progress].
  ///
  /// The arrow stays for the whole stage. The second half of the sequence is
  /// reached by clicking it *again*, so hiding it once the user starts would
  /// strand anyone without a wheel — the affordance has to outlive the
  /// gesture it invited. It clears only with the final flash, when the text
  /// and starfield do.
  static double cueVisibility(double progress) =>
      1 - ((progress - splashStart) / (1 - splashStart)).clamp(0.0, 1.0);
}
