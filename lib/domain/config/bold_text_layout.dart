import 'dart:math' as math;
import 'dart:ui' show Size;

/// How "Crafting clarity from chaos." is set for a screen.
///
/// The text is rasterised once into a texture and drawn centred at its own
/// size. With the desktop's numbers (64 px type, wrapped at 800 px) a phone
/// 412 px wide cut "Crafting Clarity from" off at both sides. Below
/// [designWidth] the type scales with the screen's width, and it wraps at the
/// screen less [sideMargin] each side; at or above it, nothing changes.
abstract final class BoldTextLayout {
  /// The widest line the text may take: today's desktop wrap.
  static const double maxWrapWidth = 800;

  /// Clear space either side on a narrow screen (Material's 16 dp margin).
  static const double sideMargin = 16;

  /// At this width and above the type is its full size. A 412-wide phone
  /// gets 412 / 720 of 64, about 36 px: Material's display-small size, and
  /// the same two lines the desktop shows.
  static const double designWidth = 720;

  /// Never smaller than half size, however narrow the window.
  static const double minScale = 0.5;

  /// The width the text wraps at on a screen of [viewport].
  static double wrapWidthFor(Size viewport) =>
      math.max(0, math.min(maxWrapWidth, viewport.width - sideMargin * 2));

  /// How much the type is scaled on a screen of [viewport], [minScale] to 1.
  static double scaleFor(Size viewport) =>
      (viewport.width / designWidth).clamp(minScale, 1.0);
}
