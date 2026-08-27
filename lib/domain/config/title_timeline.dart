import 'package:flutter/animation.dart';
import 'package:portfolio/domain/config/title_config.dart';

/// The hero title's choreography, as pure maths.
///
/// Split out from the component so the ordering can be tested without a game
/// loop. The stage is a sequence of overlapping windows rather than a chain
/// of callbacks, which means any moment can be evaluated directly — useful
/// for tests, and it makes the stage resumable rather than dependent on
/// having observed every frame.
///
/// All values are seconds since the stage began.
abstract final class TitleTimeline {
  /// When the name begins resolving: a beat after the mark parks, then a
  /// further pause.
  static double get primaryStart =>
      _seconds(TitleConfig.entranceDelay) + _seconds(TitleConfig.revealDelay);

  static double get primaryEnd =>
      primaryStart + _seconds(TitleConfig.primaryDuration);

  /// When the line beneath is released. It follows the name, not the clock.
  ///
  /// Only the start lives here — the line runs its own per-glyph
  /// choreography ([SecondaryTitleTimeline]) and reports for itself, so there
  /// is no end for this timeline to track.
  static double get secondaryStart => primaryEnd;

  /// The drift begins before the fade has finished, so the name is already
  /// moving as it resolves rather than settling and then twitching.
  static double get driftStart =>
      primaryStart + _seconds(TitleConfig.driftDelay);

  static double get driftEnd =>
      driftStart + _seconds(TitleConfig.driftDuration);

  /// How far the name has resolved, `0`..`1`.
  static double primary(double elapsed) => _window(
    elapsed,
    from: primaryStart,
    to: primaryEnd,
    curve: Curves.easeOutCubic,
  );

  /// How far through the upward heat drift, `0`..`1`.
  static double drift(double elapsed) => _window(
    elapsed,
    from: driftStart,
    to: driftEnd,
    curve: Curves.easeInOut,
  );

  static double _seconds(Duration d) => d.inMilliseconds / 1000;

  static double _window(
    double elapsed, {
    required double from,
    required double to,
    required Curve curve,
  }) {
    if (elapsed <= from) return 0;
    if (elapsed >= to) return 1;
    return curve.transform((elapsed - from) / (to - from));
  }
}
