/// The shine the light lays on the title's metallic letters (the specular
/// hit in `metallic_text.frag`), and how wide it is (PORTFOLIO-30).
///
/// Vishal, 2026-11-22: "there is shine that react to cursor movements, hover
/// and tilt in title screen, can we increase the radius of that shine?".
abstract final class TitleShine {
  /// The shine's radius against the shader's original (1 = as it was).
  /// Shot at 1, 1.5 and 2 on desktop and the ROG (2026-11-22): 2 ships, as it
  /// read best on the phone. The name's contrast at the brightest frame with
  /// the shine on it holds on desktop (3.55 / 3.54 / 3.59:1 at 1 / 1.5 / 2)
  /// and on the ROG at 2 (4.37:1). The radius is in logical pixels on every
  /// screen (Flame's canvas reports a device pixel ratio of 1, the ROG
  /// included), so on a phone, whose name is narrower, it already covers
  /// more of the name than on a desktop. One constant away (`?pc-shine=`).
  static const double radiusScale = 2;

  /// The scale in use: [radiusScale], or `?pc-shine=N` on the URL.
  static final double inUse =
      double.tryParse(Uri.base.queryParameters['pc-shine'] ?? '') ??
      radiusScale;
}
