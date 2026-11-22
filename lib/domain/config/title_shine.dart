/// The shine the light lays on the title's metallic letters (the specular
/// hit in `metallic_text.frag`), and how wide it is (PORTFOLIO-30).
///
/// Vishal, 2026-11-22: "there is shine that react to cursor movements, hover
/// and tilt in title screen, can we increase the radius of that shine?".
abstract final class TitleShine {
  /// The shine's radius against the shader's original (1 = as it was).
  /// Shot at 1, 1.5 and 2 on desktop and the ROG (2026-11-22): 2 ships. The
  /// shader's radius is in physical pixels, so on a phone (DPR 2.6 on the
  /// ROG) the shine is far narrower against the name than on a desktop, and
  /// at 1.5 it barely showed there; at 2 it reads, and the name's contrast at
  /// the brightest frame holds on desktop (3.55 / 3.54 / 3.59:1 at 1 / 1.5 /
  /// 2). One constant away (`?pc-shine=1|1.5|2` to compare).
  static const double radiusScale = 2;

  /// The shine's radius at scale 1, as a share of the name's drawn width:
  /// the shader's original 800 px against the desktop name's 518 px
  /// (1280 wide, measured 2026-11-21), so a desktop looks exactly as before.
  static const double nameShare = 800 / 518;

  /// The radius in physical pixels for a name [nameWidth] logical pixels
  /// wide at [devicePixelRatio], at [scale]. Desktop (518 px, DPR 1, 2x):
  /// 1600, as shipped; a phone gets the same share of its own name.
  static double radiusFor({
    required double nameWidth,
    required double devicePixelRatio,
    double? scale,
  }) => nameWidth * devicePixelRatio * nameShare * (scale ?? inUse);

  /// The name's width before the title has laid out: the desktop's.
  static const double fallbackNameWidth = 518;

  /// The scale in use: [radiusScale], or `?pc-shine=N` on the URL.
  static final double inUse =
      double.tryParse(Uri.base.queryParameters['pc-shine'] ?? '') ??
      radiusScale;
}
