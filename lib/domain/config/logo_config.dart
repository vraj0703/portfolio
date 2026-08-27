/// Geometry and physics for the logo layer, carried over from the previous
/// site so the mark and its "tap to enter" affordance read the same.
///
/// Colours and type deliberately live in the theme instead — these are the
/// values a Flame component needs, and Flame components have no
/// [BuildContext] to read a theme from.
abstract final class LogoConfig {
  /* -- Mark ------------------------------------------------------------ */

  /// Fraction of the viewport's width the mark spans.
  static const double markSizeFactor = 0.30;
  static const double markMaxSize = 460;

  /// Ceiling on the mark's height as a fraction of the viewport, so a short
  /// or landscape window cannot let it crowd out the affordance beneath it.
  static const double markMaxHeightFactor = 0.5;

  /// The logo art is 175x150.
  static const double markAspect = 150 / 175;

  /// Width of the mark for a given viewport.
  ///
  /// Shared by the loading curtain and the scene deliberately. They show the
  /// same logo either side of the reveal, and when they sized it differently
  /// it visibly changed size as the curtain opened — the two were using
  /// different bases, one the viewport's width and the other its shorter
  /// edge, which on a landscape window is a large discrepancy.
  static double markWidthFor({
    required double viewportWidth,
    required double viewportHeight,
  }) {
    final byWidth = viewportWidth * markSizeFactor;
    final capped = byWidth < markMaxSize ? byWidth : markMaxSize;

    final maxHeight = viewportHeight * markMaxHeightFactor;
    final heightLimited = maxHeight / markAspect;

    return capped < heightLimited ? capped : heightLimited;
  }

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

  /// Where the mark retreats to once dismissed, and how small it gets. It
  /// parks in the top-left as a header mark while the title takes the stage.
  static const double exitMargin = 60;
  static const double exitScale = 0.2;

  /// How long the mark takes to travel and shrink.
  static const Duration exitDuration = Duration(milliseconds: 1100);

  /// How fast the text un-types when the layer is dismissed, in fractions of
  /// the string per second.
  static const double textExitSpeed = 2;
}
