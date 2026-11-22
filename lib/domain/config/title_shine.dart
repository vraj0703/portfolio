/// The shine the light lays on the title's metallic letters (the specular
/// hit in `metallic_text.frag`), and how wide it is (PORTFOLIO-30).
///
/// Vishal, 2026-11-22: "there is shine that react to cursor movements, hover
/// and tilt in title screen, can we increase the radius of that shine?".
abstract final class TitleShine {
  /// The shine's radius against the shader's original (1 = as it was).
  /// Shot at 1, 1.5 and 2 on desktop and the ROG; one constant away
  /// (`?pc-shine=1|1.5|2` to compare).
  static const double radiusScale = 1.5;

  /// The scale in use: [radiusScale], or `?pc-shine=N` on the URL.
  static final double inUse =
      double.tryParse(Uri.base.queryParameters['pc-shine'] ?? '') ??
      radiusScale;
}
