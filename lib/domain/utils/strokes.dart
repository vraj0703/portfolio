/// The title's scroll as strokes rather than distance: one swipe or one
/// flick of the wheel carries the visitor from one pause to the next, as a
/// timed, eased move, however far the finger went.
///
/// Vishal, 2026-11-18: title to gallery in two strokes. The first carries
/// the title away to the bold text; the second carries the bold text on
/// into the gallery. Finger-distance scrolling made reading the stage a
/// handful of full-screen swipes, and stopping half-way through a move
/// was never a place anyone wanted to be.
abstract final class Strokes {
  // -- The tuning, in one place. --------------------------------------------

  /// How long a stroke's move takes, from one pause to the next.
  static const double moveSeconds = 0.9;

  /// How far a finger travels, in logical pixels, before a drag counts as a
  /// stroke: past a tap's wobble, well short of a deliberate swipe.
  static const double dragThreshold = 24;

  /// The quiet, in milliseconds, that separates one wheel stroke from the
  /// next. A flick of a wheel or a trackpad arrives as a burst of events,
  /// with inertia on a trackpad; it is one stroke for as long as the events
  /// keep coming closer together than this.
  static const int wheelBurstGapMs = 300;

  // -- The rules. -----------------------------------------------------------

  /// The direction a drag [travelled] logical pixels down the screen asks
  /// for: `1` onward (the finger went up, like a page), `-1` back, or `0`
  /// while it is still too short to say.
  static int dragDirection(double travelled) {
    if (travelled.abs() < dragThreshold) return 0;
    return travelled < 0 ? 1 : -1;
  }

  /// Whether a wheel event at [nowMs] begins a new stroke, given the last
  /// wheel event at [lastMs] (null if there has been none).
  static bool wheelStartsStroke(int nowMs, int? lastMs) =>
      lastMs == null || nowMs - lastMs > wheelBurstGapMs;

  /// The direction a wheel [delta] asks for: down is onward.
  static int wheelDirection(double delta) => delta == 0
      ? 0
      : delta > 0
      ? 1
      : -1;

  /// How far through a move [elapsed] seconds in is, eased in and out
  /// (cubic), `0`..`1`.
  static double eased(double elapsed, {double seconds = moveSeconds}) {
    final u = seconds <= 0 ? 1.0 : (elapsed / seconds).clamp(0.0, 1.0);
    return u < 0.5 ? 4 * u * u * u : 1 - _cube(-2 * u + 2) / 2;
  }

  static double _cube(double x) => x * x * x;
}
