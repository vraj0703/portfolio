import 'package:flutter/animation.dart';

/// The secondary title's per-character entry, as pure maths.
///
/// Every glyph runs the same four-part move — fade, rise, squash, elastic
/// settle — offset by its position in the line, while the line as a whole
/// slides in from the left. The stagger is what turns a caption appearing
/// into a caption being *typed into place*.
///
/// Split from the component so the choreography can be tested without a game
/// loop, and evaluated at any moment rather than depending on having observed
/// every frame.
abstract final class SecondaryTitleTimeline {
  /// Delay between one glyph starting and the next.
  static const double stagger = 0.05;

  /// Each glyph fades in over this, from the moment its turn comes.
  static const double fadeDuration = 0.4;

  /// It also rises into place, from [riseFrom] pixels below.
  static const double riseDuration = 0.8;
  static const double riseFrom = 40;

  /// Then squashes, then settles elastically. The squash is what gives the
  /// settle something to spring back from — without it the elastic reads as
  /// a wobble rather than as weight.
  static const double squashDuration = 0.6;
  static const double settleDuration = 0.6;
  static const double squashX = 0.95;
  static const double squashY = 1.1;

  /// The whole line slides in from the left underneath the per-glyph work.
  ///
  /// Short and shallow on purpose. A long travel from far out reads as the
  /// line arriving from off-screen, which competes with the glyphs landing
  /// individually — the slide is meant to be a settle, not a journey. It also
  /// finishes early, so the tail of the entry is glyph work alone.
  static const double slideDuration = 0.9;
  static const double slideFrom = -36;
  static const Cubic slideCurve = Cubic(0.25, 0.1, 0.25, 1);

  /// How long one glyph takes from its own start to fully settled.
  static const double perGlyph = squashDuration + settleDuration;

  /// When the glyph at [index] begins.
  static double startOf(int index) => index * stagger;

  /// Total length of the entry for a line of [glyphCount] glyphs.
  static double durationFor(int glyphCount) {
    if (glyphCount <= 0) return 0;
    return startOf(glyphCount - 1) + perGlyph;
  }

  /// True once every glyph has settled.
  static bool isComplete(double elapsed, int glyphCount) =>
      elapsed >= durationFor(glyphCount);

  /// Horizontal offset of the line as a whole.
  static double slideOffset(double elapsed) =>
      slideFrom * (1 - _window(elapsed, 0, slideDuration, slideCurve));

  /// Opacity of the glyph at [index], `0`..`1`.
  static double opacityOf(double elapsed, int index) =>
      _window(_local(elapsed, index), 0, fadeDuration, Curves.easeOut);

  /// How far the glyph at [index] still has to rise, in pixels.
  static double riseOf(double elapsed, int index) =>
      riseFrom *
      (1 - _window(_local(elapsed, index), 0, riseDuration, Curves.easeOutCubic));

  /// Horizontal scale of the glyph at [index].
  static double scaleXOf(double elapsed, int index) =>
      _scale(_local(elapsed, index), squashX);

  /// Vertical scale of the glyph at [index].
  static double scaleYOf(double elapsed, int index) =>
      _scale(_local(elapsed, index), squashY);

  /// Squash out to [extreme], then settle elastically back to 1.
  static double _scale(double local, double extreme) {
    if (local <= 0) return 1;

    if (local < squashDuration) {
      final t = Curves.easeOut.transform(local / squashDuration);
      return 1 + (extreme - 1) * t;
    }

    final t = _window(
      local,
      squashDuration,
      squashDuration + settleDuration,
      Curves.elasticOut,
    );
    return extreme + (1 - extreme) * t;
  }

  /// Seconds since the glyph at [index] started. Negative before its turn.
  static double _local(double elapsed, int index) => elapsed - startOf(index);

  static double _window(double t, double from, double to, Curve curve) {
    if (t <= from) return 0;
    if (t >= to) return 1;
    return curve.transform((t - from) / (to - from));
  }
}
