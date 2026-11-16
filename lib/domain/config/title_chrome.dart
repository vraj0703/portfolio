import 'dart:ui' show Offset, Rect, Size;

import 'logo_config.dart';

/// The title's header row on a compact screen: the parked mark on the left,
/// the three actions (sound, connect, menu) on the right.
///
/// Material's guidance for a compact window (narrower than [compactWidth]):
/// [icon] glyphs in [target] touch targets, one size for all three,
/// [edge] from the screen's edges, spacing on the [grid], clear of the
/// system insets. The mark is sized by one rule beside them: [markHeight],
/// its middle on the row's middle.
///
/// A wider screen keeps the desktop layout exactly ([LogoConfig.exitMargin],
/// the mark at [LogoConfig.exitScale] of its home size, glyphs from the mark).
abstract final class TitleChrome {
  /// Below this width a window is compact (Material window size classes).
  static const double compactWidth = 600;

  static const double grid = 8;
  static const double icon = 3 * grid;
  static const double target = 6 * grid;
  static const double edge = 2 * grid;

  /// Targets abut: their 12 dp of padding each side already parts the glyphs
  /// by 24 dp, and a further gap would push the row past a third of a
  /// 360-wide phone.
  static const double gap = 0;

  /// The parked mark's height: one grid step over the icons, so it reads as
  /// the logo rather than a fourth button.
  static const double markHeight = 4 * grid;

  static bool isCompact(Size viewport) => viewport.width < compactWidth;

  /// Where the parked mark sits on a compact screen: its left edge at [edge],
  /// its middle on the action row's middle.
  ///
  /// No system insets here: the page's viewport meta has no
  /// `viewport-fit=cover`, so the browser already keeps the page clear of
  /// them and they read as zero. The action row still adds
  /// `MediaQuery.paddingOf` in case that changes.
  static Rect compactMarkRect(Size viewport) {
    final width = markHeight / LogoConfig.markAspect;
    const rowMiddle = edge + target / 2;
    return Rect.fromCenter(
      center: Offset(edge + width / 2, rowMiddle),
      width: width,
      height: markHeight,
    );
  }
}
