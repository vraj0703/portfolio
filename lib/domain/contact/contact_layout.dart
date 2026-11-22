import 'package:portfolio/domain/config/logo_config.dart';

/// How the contact screen's links stand on a phone (PORTFOLIO-29).
///
/// Vishal, 2026-11-22: "the text line in the contact section in phone screen
/// resolution is also not taking much space and properly readable". Today's
/// row is sized for a wide screen and scaled down to fit a phone, which left
/// 21 px type at about 8 px.
enum ContactArrangement {
  /// Today's single row, scaled to fit (desktop; and on a phone, for
  /// comparison only).
  row,

  /// (a) The same row, larger, wrapped onto centred lines.
  wrapped,

  /// (b) A centred vertical list, one link per line, each a full-width row.
  list,

  /// (c) Two columns.
  columns,
}

/// The sizes one arrangement takes on one screen. Pure.
class ContactLayoutSpec {
  const ContactLayoutSpec({
    required this.arrangement,
    required this.fontScale,
    required this.targetHeight,
    required this.blockWidth,
    required this.bottom,
  });

  final ContactArrangement arrangement;

  /// The words' size against their designed size (21 px): 1 on desktop.
  final double fontScale;

  /// Each link's touch height (0: as designed, the desktop row).
  final double targetHeight;

  /// The width the links stand in.
  final double blockWidth;

  /// From the screen's bottom edge to the block's bottom.
  final double bottom;

  bool get onPlate => arrangement != ContactArrangement.row;
}

abstract final class ContactLayout {
  /// The arrangement a phone ships with. One constant away from the others;
  /// `?pc-contact=a|b|c|row` to compare them on a device.
  static const ContactArrangement phoneArrangement = ContactArrangement.wrapped;

  static final ContactArrangement phoneInUse = _fromUrl() ?? phoneArrangement;

  static ContactArrangement? _fromUrl() =>
      switch (Uri.base.queryParameters['pc-contact']) {
        'a' => ContactArrangement.wrapped,
        'b' => ContactArrangement.list,
        'c' => ContactArrangement.columns,
        'row' => ContactArrangement.row,
        _ => null,
      };

  /// The words' designed size (`contactMenu`), and a phone's: 18 px, above
  /// the 16 px floor.
  static const double designFontSize = 21;
  static const double phoneFontSize = 18;
  static const double minFontSize = 16;

  /// A touch target's height: Material's 48 dp.
  static const double targetHeight = 48;

  /// Clear space either side of the block, and below it.
  static const double sideMargin = 16;
  static const double phoneBottom = 28;

  /// The plate: its corner radius and inner padding; the wrapped row's gap
  /// between links.
  static const double plateRadius = 14;
  static const double platePadding = 8;
  static const double wrapSpacing = 6;

  /// The desktop row's height (as `ContactMenuLayer.rowHeight`).
  static const double rowHeight = 44;

  /// The layout for a screen [width] by [height]. Anything but a portrait
  /// phone gets today's row exactly; a portrait phone gets [arrangement]
  /// (default [phoneInUse]).
  static ContactLayoutSpec forScreen(
    double width,
    double height, {
    ContactArrangement? arrangement,
  }) {
    if (!LogoConfig.isPortraitPhone(width, height)) {
      return ContactLayoutSpec(
        arrangement: ContactArrangement.row,
        fontScale: 1,
        targetHeight: 0,
        blockWidth: LogoConfig.contactGap(width) * 2,
        bottom: LogoConfig.overlayBottomMargin - rowHeight / 2,
      );
    }
    final chosen = arrangement ?? phoneInUse;
    if (chosen == ContactArrangement.row) {
      return ContactLayoutSpec(
        arrangement: ContactArrangement.row,
        fontScale: 1,
        targetHeight: 0,
        blockWidth: LogoConfig.contactGap(width) * 2,
        bottom: LogoConfig.overlayBottomMargin - rowHeight / 2,
      );
    }
    return ContactLayoutSpec(
      arrangement: chosen,
      fontScale: phoneFontSize / designFontSize,
      targetHeight: targetHeight,
      blockWidth: width - sideMargin * 2,
      bottom: phoneBottom,
    );
  }
}
