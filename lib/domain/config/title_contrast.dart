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
}

abstract final class TitleContrastConfig {
  /// The way the site ships. Change this one line to choose another.
  static const TitleContrast chosen = TitleContrast.dimBand;

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

  /// The dimming strength for [way] (0 = none).
  static double dimFor(TitleContrast way) => switch (way) {
    TitleContrast.dimBand => dimStrength,
    TitleContrast.dimAndDarker => dimStrengthLight,
    _ => 0,
  };

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
