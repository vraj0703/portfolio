import 'dart:math' as math;
import 'dart:ui' show Size;

import 'logo_config.dart';

/// The loading screen's sizes, from the device's screen rather than fixed.
///
/// On a phone held upright the width rule the desktop uses
/// ([LogoConfig.loadingMarkWidthFor], 30% of the width) made the mark about
/// 96 px, and the readout, boxed to the mark's width, broke "LOADING..." over
/// three lines. A portrait screen sizes both from its own short side instead;
/// a landscape screen keeps today's rule exactly.
abstract final class LoadingLayout {
  /// The mark on a portrait screen, as a share of the screen's short side.
  static const double portraitMarkShare = 0.42;

  /// Clear space either side of the readout (Material's 16 dp margin).
  static const double sideMargin = 16;

  /// The short side the readout's type is designed at; smaller screens scale
  /// it down, never below [minReadoutScale], and never up.
  static const double readoutDesignShortSide = 480;
  static const double minReadoutScale = 0.8;

  /// Width of the loading screen's mark on a screen of [size].
  static double markWidthFor(Size size) {
    if (!isPortrait(size)) {
      return LogoConfig.loadingMarkWidthFor(
        viewportWidth: size.width,
        viewportHeight: size.height,
      );
    }
    final byShortSide = size.shortestSide * portraitMarkShare;
    // The same height cap the scene's mark has, so a very short portrait
    // window does not push the readout off the screen.
    final heightCap =
        size.height * LogoConfig.markMaxHeightFactor / LogoConfig.markAspect;
    return math.min(byShortSide, heightCap);
  }

  /// How wide the readout may be. On a portrait screen, the screen less its
  /// margins, not the mark, so the label never wraps under a small mark; on a
  /// landscape screen, the mark's width [markWidth], as it always was.
  static double readoutWidthFor(Size size, double markWidth) =>
      isPortrait(size) ? math.max(0, size.width - sideMargin * 2) : markWidth;

  /// Whether the readout sits under the mark's right edge (landscape, as it
  /// always has) or centred under it (portrait, where it is wider than it).
  static bool readoutAlignsRight(Size size) => !isPortrait(size);

  static bool isPortrait(Size size) => size.width < size.height;

  /// The air between the mark and the readout: on a portrait screen a share
  /// of the mark's height, so the larger phone mark is not crowded by the
  /// text under it (Vishal, 2026-11-22: "we need some space between logo
  /// and loading text"); elsewhere the fixed gap it always had.
  static double readoutGapFor(Size size, double markHeight) =>
      isPortrait(size) ? markHeight * portraitGapShare : landscapeGap;

  /// A quarter to a third of the mark's height, as asked: 0.3.
  static const double portraitGapShare = 0.3;
  static const double landscapeGap = 20;

  /// How much the readout's type is scaled on a screen of [size], 0.8 to 1.
  static double readoutScaleFor(Size size) =>
      (size.shortestSide / readoutDesignShortSide).clamp(minReadoutScale, 1.0);
}
