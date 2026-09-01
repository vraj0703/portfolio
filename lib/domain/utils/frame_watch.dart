import 'package:flutter/foundation.dart';

/// Reports frames that took materially longer than they should have.
///
/// Diagnostic scaffolding, not scenery. It exists because a hitch in the
/// corridor has now outlived two confident explanations — lazy texture upload
/// and an under-covered warm-up — and neither survived being checked. What is
/// missing is not another theory but a measurement: *when* the slow frames
/// happen, and how long they take.
///
/// Deliberately not gated on `kDebugMode`. The only place the fault appears is
/// the deployed site, so a report that only exists in a debug build reports
/// nothing at all. It stays quiet by construction instead: nothing is printed
/// under [threshold], and it stops printing entirely after [budget] reports,
/// so a persistent problem cannot turn into a persistent stream of logging.
class FrameWatch {
  FrameWatch({
    this.label = 'frame',
    this.threshold = const Duration(milliseconds: 40),
    this.budget = 30,
  });

  /// What to call this in the log, so two watches can be told apart.
  final String label;

  /// How long a frame has to take before it is worth mentioning.
  ///
  /// Forty milliseconds is two and a half frames at sixty. Below that the eye
  /// reads a scroll as smooth, and above it the stutter is the thing being
  /// complained about.
  final Duration threshold;

  /// How many slow frames are reported before it falls silent.
  final int budget;

  final Stopwatch _clock = Stopwatch()..start();

  int _previous = 0;
  int _reported = 0;
  int _seen = 0;

  /// How many slow frames have been seen, reported or not.
  int get slowFrames => _seen;

  /// Call once a frame. [where] is whatever context makes the report useful —
  /// scroll position, which stage, what the visitor was doing.
  void tick(String where) {
    final now = _clock.elapsedMicroseconds;
    final previous = _previous;
    _previous = now;

    // The first tick has nothing to measure against: the gap would be the
    // time since this was constructed, which is not a frame and would always
    // look like a stall.
    if (previous == 0) return;

    final gap = now - previous;
    if (gap < threshold.inMicroseconds) return;
    _seen++;

    if (_reported >= budget) return;
    _reported++;

    debugPrint(
      '[$label] ${(gap / 1000).toStringAsFixed(0)}ms — $where'
      '${_reported == budget ? ' (last report; budget spent)' : ''}',
    );
  }
}
