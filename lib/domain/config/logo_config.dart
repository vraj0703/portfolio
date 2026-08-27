/// Geometry and physics for the logo layer, carried over from the previous
/// site so the mark and its "tap to enter" affordance read the same.
///
/// Colours and type deliberately live in the theme instead — these are the
/// values a Flame component needs, and Flame components have no
/// [BuildContext] to read a theme from.
abstract final class LogoConfig {
  /* -- Mark ------------------------------------------------------------ */

  /// Fraction of the viewport's width the mark spans in the scene.
  static const double markSizeFactor = 0.30;

  /// Ceiling on the scene's mark, so a very wide monitor does not turn it
  /// into a billboard.
  static const double logoMarkMaxSize = 460;

  /// How large the loading screen's mark is *relative to* the scene's.
  ///
  /// Expressed as a ratio rather than its own cap. A cap only takes effect
  /// once the computed size exceeds it, so two marks sharing one size factor
  /// and differing only in their ceilings come out identical on any viewport
  /// narrow enough that neither ceiling applies — which is most of them —
  /// and identical again on a short window, where the height clamp binds both
  /// equally. A ratio holds at every size.
  static const double loadingMarkScale = 0.78;

  /// Ceiling on the mark's height as a fraction of the viewport, so a short
  /// or landscape window cannot let it crowd out the affordance beneath it.
  static const double markMaxHeightFactor = 0.5;

  /// The logo art is 175x150.
  static const double markAspect = 150 / 175;

  /// Width of the scene's mark for a given viewport.
  ///
  /// Both marks derive from this one measurement, so they can differ in size
  /// without differing in *rule*. An earlier version sized them from separate
  /// bases — one the viewport's width, the other its shorter edge — and the
  /// logo visibly jumped size as the curtain opened, by roughly a factor of
  /// two on a landscape window.
  ///
  /// The mark still grows across the reveal, deliberately now, and by
  /// [loadingMarkScale] rather than by accident.
  static double logoMarkWidthFor({
    required double viewportWidth,
    required double viewportHeight,
  }) {
    return _markWidthFor(
      viewportWidth: viewportWidth,
      viewportHeight: viewportHeight,
      markMaxSize: logoMarkMaxSize,
    );
  }

  /// Width of the loading screen's mark: the scene's, scaled down.
  static double loadingMarkWidthFor({
    required double viewportWidth,
    required double viewportHeight,
  }) {
    return logoMarkWidthFor(
          viewportWidth: viewportWidth,
          viewportHeight: viewportHeight,
        ) *
        loadingMarkScale;
  }

  static double _markWidthFor({
    required double viewportWidth,
    required double viewportHeight,
    required double markMaxSize,
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
