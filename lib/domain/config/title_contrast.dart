/// How "VISHAL RAJ" holds its own against the backdrop's bright band
/// (PORTFOLIO-22: on web and phone the name was overwhelmed at the
/// animation's brightest moment).
///
/// Four ways, each one constant away ([TitleContrastConfig.chosen]):
enum TitleContrast {
  /// As it was: the name on the band.
  none,

  /// (A) A soft local dimming in the backdrop behind the name.
  dimBand,

  /// (B) The name itself: darker metal, a soft dark shadow, more weight.
  darkerName,

  /// (C) The name moved off the bright band onto darker sky.
  offBand,

  /// (D) A and B, both lighter.
  dimAndDarker,

  /// (E) A's dimming made part of the picture: warm (toward the dunes'
  /// shadow brown, not grey), feathered wider and softer, only as wide as
  /// the name with a soft falloff; with a slightly brighter, heavier name.
  warmBand,
}

abstract final class TitleContrastConfig {
  /// The way the site ships. Change this one line to choose another.
  static const TitleContrast chosen = TitleContrast.warmBand;

  /// The way in use: [chosen], or `?pc-title=none|A|B|C|D` on the URL, for
  /// shooting the four side by side. Read once.
  static final TitleContrast current = _fromUrl() ?? chosen;

  // -- (A) the dimming, in the backdrop's own units (uv: screen height = 1,
  //    centre 0, up positive). A soft ellipse round the name.
  static const double dimStrength = 0.5;
  static const double dimStrengthLight = 0.3;
  static const double dimHalfWidth = 0.75;
  static const double dimHalfHeight = 0.11;

  // -- (B) the name: a darker metal, a soft shadow, a heavier weight.
  static const int darkerBase = 0xFFB9B3A8;
  static const int darkerBaseLight = 0xFFCDC8BF;
  static const double shadowBlur = 14;
  static const double shadowAlpha = 0.55;
  static const double shadowAlphaLight = 0.4;

  // -- (C) where the name moves: up the screen, as a share of its height.
  static const double offBandRise = 0.2;

  // -- (E) the warm band and its name.
  static const double warmStrength = 0.62;
  static const double warmHalfHeight = 0.2;
  static const double warmShape = 6;
  static const double warmMargin = 0.08; // beyond the name, in uv
  static const int warmNameBase = 0xFFF0EEEA;

  /// The name's measured half width in logical pixels, set by the title as
  /// it lays out, so (E)'s band is only as wide as the name.
  static double nameHalfWidthPx = 0;

  /// The dimming strength for [way] (0 = none).
  static double dimFor(TitleContrast way) => switch (way) {
    TitleContrast.dimBand => dimStrength,
    TitleContrast.dimAndDarker => dimStrengthLight,
    TitleContrast.warmBand => warmStrength,
    _ => 0,
  };

  /// The band's half width in uv for [way] on a screen [height] tall.
  static double halfWidthFor(TitleContrast way, double height) =>
      way == TitleContrast.warmBand && nameHalfWidthPx > 0 && height > 0
      ? nameHalfWidthPx / height + warmMargin
      : dimHalfWidth;
  static double halfHeightFor(TitleContrast way) =>
      way == TitleContrast.warmBand ? warmHalfHeight : dimHalfHeight;
  static double warmFor(TitleContrast way) =>
      way == TitleContrast.warmBand ? 1 : 0;
  static double shapeFor(TitleContrast way) =>
      way == TitleContrast.warmBand ? warmShape : 2;

  /// How far the name rises (share of screen height) for [way].
  static double riseFor(TitleContrast way) =>
      way == TitleContrast.offBand ? offBandRise : 0;

  static TitleContrast? _fromUrl() {
    final v = Uri.base.queryParameters['pc-title'];
    return switch (v) {
      'none' => TitleContrast.none,
      'A' => TitleContrast.dimBand,
      'B' => TitleContrast.darkerName,
      'C' => TitleContrast.offBand,
      'D' => TitleContrast.dimAndDarker,
      'E' => TitleContrast.warmBand,
      _ => null,
    };
  }

  /// Shooting aids, never set by a visitor: `?pc-time=S` pins the backdrop's
  /// clock (the same frame for every way), `?pc-noname` hides the name (the
  /// backdrop behind it, for measuring contrast).
  static final double? pinnedTime = double.tryParse(
    Uri.base.queryParameters['pc-time'] ?? '',
  );
  static final bool hideName = Uri.base.queryParameters.containsKey(
    'pc-noname',
  );
}
