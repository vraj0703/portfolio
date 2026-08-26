/// Geometry and physics for the logo layer, carried over from the previous
/// site so the mark and its "tap to enter" affordance read the same.
///
/// Colours and type deliberately live in the theme instead — these are the
/// values a Flame component needs, and Flame components have no
/// [BuildContext] to read a theme from.
abstract final class LogoConfig {
  /* -- Mark ------------------------------------------------------------ */

  /// Fraction of the shorter viewport edge the mark spans.
  static const double markSizeFactor = 0.22;
  static const double markMaxSize = 340;

  /// The logo art is 175x150.
  static const double markAspect = 150 / 175;

  /* -- Overlay --------------------------------------------------------- */

  /// Distance from the bottom of the viewport to the affordance.
  static const double overlayBottomMargin = 100;

  /// Length of each line at rest, and the gap from centre to its inner end.
  static const double lineLength = 80;
  static const double lineGap = 120;

  /// How far the lines travel at the extremes of cursor movement.
  static const double lineTravel = 300;

  /// The lines taper: thick at the inner end, near-nothing at the outer.
  static const double lineStartThickness = 3;
  static const double lineEndThickness = 0.5;

  /* -- Spring ---------------------------------------------------------- */

  static const double springStiffness = 500;
  static const double springDamping = 70;
  static const double springMass = 20;

  /// Lines stretch as they move; this caps how far and how fast.
  static const double lineMaxScale = 2;
  static const double lineScaleSpeed = 15;
  static const double lineVelocityScaleFactor = 70;

  /// Explicit Euler integration goes unstable if a frame is long enough, and
  /// a backgrounded tab produces exactly that. Clamping the step trades a
  /// little accuracy after a stall for never exploding.
  static const double maxStep = 1 / 30;

  /* -- Entrance -------------------------------------------------------- */

  /// The layer fades in, then the lines arrive, then the text types on.
  /// Fractions of [entranceDuration].
  static const double linesStart = 0.25;
  static const double textStart = 0.45;

  static const Duration entranceDuration = Duration(milliseconds: 1400);

  /* -- Exit ------------------------------------------------------------ */

  /// How fast the text un-types when the layer is dismissed, in fractions of
  /// the string per second.
  static const double textExitSpeed = 2;
}
