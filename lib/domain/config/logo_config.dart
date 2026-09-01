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

  /// How far the lines stand apart on the contact screen.
  ///
  /// Wider, because what stands between them there is a row of seven
  /// destinations rather than three words. Derived from the viewport rather
  /// than fixed: the menu is the widest thing on that screen, and a constant
  /// clear enough for a desktop puts both lines off the edge of a phone.
  ///
  /// Read by the lines *and* by the menu, so the two cannot drift — the
  /// failure otherwise is a menu that overruns its own rules, which reads as
  /// a layout bug rather than as a design.
  static double contactGap(double viewportWidth) =>
      (viewportWidth * 0.34).clamp(minContactGap, maxContactGap);

  static const double minContactGap = 130;
  static const double maxContactGap = 300;

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
  /// Where the label starts writing itself.
  ///
  /// Back at 0.45, where it was before it was moved to 0.608 to fit a typing
  /// sound to the window. That sound is gone — it was the only cue in the
  /// app that fired before the visitor had clicked anything, which is the
  /// one thing a browser will not play — and the phase boundary it dragged
  /// with it has no reason to stay moved.
  static const double textStart = 0.45;

  static const Duration entranceDuration = Duration(milliseconds: 1400);

  /// The progress by which the mark is fully on.
  ///
  /// The mark arrives with the *work*, not on a clock of its own. It starts
  /// hidden and comes up through the first half of the load, which leaves
  /// the second half to the aura and the flash that were already built to
  /// carry it — so the screen has one continuous movement from nothing to
  /// the reveal rather than an entrance that finishes and then waits.
  ///
  /// A clock was the wrong instrument here for a reason worth keeping: a
  /// timed entrance says the same thing however long the load takes, so on a
  /// warm cache it is still fading up after the bar has finished, and on a
  /// cold one it is done long before anything else moves.
  static const double markRevealBy = 0.5;

  /// How far the mark has arrived at [elapsed] through its reveal.
  ///
  /// Eased at *both* ends, and the first end is the one that matters. An
  /// ease-out — which is what this was — spends most of itself immediately:
  /// a tenth of the way through it is already twenty-seven per cent on, so
  /// however long the duration, the mark still appears rather than arrives.
  /// This is under one per cent at the same point.
  ///
  /// Written out rather than taken from `Curves`, because [LogoConfig] is
  /// read by Flame components that have no widget layer to reach into — and
  /// because the shape is the decision, not the name of it.
  static double markEntranceAt(double elapsed) {
    final t = elapsed.clamp(0.0, 1.0);
    return t < 0.5 ? 4 * t * t * t : 1 - _cube(-2 * t + 2) / 2;
  }

  static double _cube(double v) => v * v * v;

  /// How long the contact menu's row takes to arrive, waiting included.
  ///
  /// Longer than the affordance's, because there is more of it: "TAP TO
  /// ENTER" is twelve characters and the menu is nearer forty, so sharing a
  /// duration means the row types more than three times as fast as the
  /// phrase it stands in for and reads as a flicker rather than as writing.
  ///
  /// Set so the typing window — the last `1 - contactMenuTextStart` of it —
  /// is `AudioCue.keyboardTyping`'s 3600ms exactly. That works out at 90ms a
  /// character, which is what the recording is: somebody typing at a normal
  /// speed. The row took 1320ms before, so the sound outlasted it by more
  /// than twice its own length.
  static const Duration contactMenuDuration = Duration(milliseconds: 4500);

  /// How much of [contactMenuDuration] passes before the row starts writing.
  ///
  /// Its own number rather than [textStart], because the two delays are
  /// waiting for different things. The affordance waits for the layer to
  /// fade and its lines to draw. The menu waits for the mark to finish
  /// travelling in from the hall, which is a shorter wait — and the row has
  /// three times as much to write once it starts, so spending the same
  /// *fraction* on waiting would push the whole thing past six seconds.
  static const double contactMenuTextStart = 0.2;

  /// The same wait as a duration, for whatever has to happen on a clock
  /// rather than on a tween — the typing sound, which cannot be expressed as
  /// a fraction of anything.
  ///
  /// Kept beside the fraction it restates instead of derived from it, since
  /// `Duration.inMilliseconds` is not available to a `const`. The two are
  /// held to each other by `logo_typing_sync_test`, because a lead that
  /// drifts from its fraction is a sound that starts before or after the
  /// writing it belongs to — which is the one thing this pair exists to
  /// prevent.
  static const Duration contactMenuLead = Duration(milliseconds: 900);

  /// How small the mark starts before it settles.
  ///
  /// Barely. A mark that swells into place reads as a splash screen; one
  /// that arrives almost at size reads as a light coming up on something
  /// already there.
  static const double markEntranceScale = 0.94;

  /// How much of the affordance has typed on at [entrance].
  ///
  /// Pure, and shared: the contact menu types its row on by the same rule,
  /// and the two are meant to be the same animation rather than two
  /// animations that happen to take the same time. [from] is the only thing
  /// they differ on — where in their own entrance the writing starts.
  static double typedAt(double entrance, {double from = textStart}) {
    if (entrance <= from) return 0;
    return ((entrance - from) / (1 - from)).clamp(0.0, 1.0);
  }

  /* -- Exit ------------------------------------------------------------ */

  /// Where the mark retreats to once dismissed, and how small it gets. It
  /// parks in the top-left as a header mark while the title takes the stage.
  static const double exitMargin = 60;
  static const double exitScale = 0.2;

  /// How long the mark takes to cross to the middle of the contact screen.
  ///
  /// The same trip from either side — the corridor flies its own mark in
  /// from the corner, and the title screen's layer walks its retreat
  /// backwards — so it is one number rather than each renderer choosing.
  ///
  /// Equal to [contactMenuLead] on purpose: the row starts writing as the
  /// mark lands. Change one and the writing either begins under a mark still
  /// in flight or after it has been sitting there.
  static const Duration contactTravel = Duration(milliseconds: 900);

  /// How long the mark takes to travel and shrink.
  static const Duration exitDuration = Duration(milliseconds: 1100);

  /// How fast the text un-types when the layer is dismissed, in fractions of
  /// the string per second.
  static const double textExitSpeed = 2;
}
