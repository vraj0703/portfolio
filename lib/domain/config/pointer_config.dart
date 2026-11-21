/// Where the scene's pointer comes from when there is no mouse
/// (PORTFOLIO-27): a finger, the phone's tilt, or a slow drift.
///
/// Every source feeds the same `CursorTracker`, so the light, the god rays,
/// the spring lines and the title's parallax read one smoothed pointer
/// whichever it is. These are the numbers that decide how far and how fast
/// the virtual ones travel.
abstract final class PointerConfig {
  /// Degrees of tilt, either way from the angle the phone was held at when
  /// the scene appeared, that carry the pointer to the screen's edge.
  static const double tiltRange = 20;

  /// A phone counts as being tilted while its angle has moved more than
  /// [tiltMoved] degrees within the last [tiltRest] seconds; a phone at rest
  /// (on a table, or held very still) gives way to the drift.
  static const double tiltMoved = 1.5;
  static const double tiltRest = 4;

  /// One pass of the idle drift, seconds. Slow enough to read as the light
  /// moving on its own, not as something trying to get attention.
  static const double driftPeriod = 16;

  /// How far the drift wanders, as a share of the travel (below): a calm
  /// path stays well inside the screen.
  static const double driftReach = 0.6;

  /// On desktop the drift takes over once the mouse has been still this long
  /// (seconds), and hands back the instant it moves.
  static const double mouseIdle = 8;

  /// Seconds a hand-over to a virtual source (tilt, drift, the centre) takes:
  /// the pointer travels from where it was to the new source along an eased
  /// path, rather than jumping and leaving the tracker to whip after it.
  /// A finger or a mouse takes over at once.
  static const double handover = 0.8;

  /// How far a virtual pointer may travel from the centre, as a share of
  /// half the screen. Tuned for a wide screen; a portrait phone gets its own
  /// smaller starting value (Vishal judges on the preview).
  static const double travelWide = 1;
  static const double travelPortrait = 0.6;

  /// The title's parallax, per pointer pixel from the centre: the wide
  /// screen's (`CursorConfig.titleParallax`, `secondaryTitleParallax`) and a
  /// portrait phone's own smaller starting values.
  static const double titleParallaxPortrait = 0.012;
  static const double secondaryTitleParallaxPortrait = 0.009;

  /// The travel for a screen [width] by [height].
  static double travelFor(double width, double height) =>
      height > width ? travelPortrait : travelWide;
}
