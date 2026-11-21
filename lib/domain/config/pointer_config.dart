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

  /// How far the drift wanders from the centre, as a share of half the
  /// screen. Tuned for a wide screen; a portrait phone gets its own smaller
  /// starting value (Vishal judges on the preview). The tilt is not scaled:
  /// its full range reaches the screen's edge, as a finger can.
  static const double travelWide = 1;
  static const double travelPortrait = 0.6;

  /// The drift's travel for a screen [width] by [height].
  static double travelFor(double width, double height) =>
      height > width ? travelPortrait : travelWide;

  /// How far the title's name and tagline slide for a full sweep of the
  /// pointer across the screen, as a share of the name's width. Measured on
  /// desktop (2026-11-21, 1280 wide): the name is 518 px, and the cursor
  /// parallax (`CursorConfig.titleParallax` 0.02, `secondaryTitleParallax`
  /// 0.015) moves it 25.6 px and the tagline 19.2 px across a full sweep:
  /// 4.94 % and 3.71 % of the name. A phone gets the same share of its own
  /// name for a full tilt or a finger across the screen, not the same pixels
  /// (Vishal, 2026-11-21: "title and subtext doesn't have parallax"). The
  /// two differ so the name and the tagline slide against each other.
  static const double titleSweepShare = 0.0494;
  static const double secondarySweepShare = 0.0371;

  /// The parallax factor (offset per pointer pixel from the centre) that
  /// moves a name [nameWidth] wide by [share] of itself for a full sweep of
  /// a screen [viewportWidth] wide. Desktop: 518 x 0.0494 / 1280 = 0.0200.
  static double parallaxFor({
    required double nameWidth,
    required double viewportWidth,
    required double share,
  }) => viewportWidth > 0 ? nameWidth * share / viewportWidth : 0;
}
