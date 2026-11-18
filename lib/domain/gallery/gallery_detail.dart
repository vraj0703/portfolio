/// How much the gallery draws per frame, by device.
///
/// On a phone the corridor is fill-rate bound: every pixel is shaded under
/// every lamp. On the ROG Phone II at DPR 2.0 it walked at 5 fps; at half
/// the render resolution, 18 (rAF recorder, 2026-11-18). Desktops and
/// tablets keep the full resolution.
class GalleryDetail {
  const GalleryDetail({required this.renderScale, required this.bakeLighting});

  /// What desktops and tablets draw: the full render size.
  static const GalleryDetail full = GalleryDetail(
    renderScale: 1,
    bakeLighting: false,
  );

  /// Phones: half the render size in each direction, a quarter of the pixels.
  static const GalleryDetail phone = GalleryDetail(
    renderScale: 0.5,
    bakeLighting: true,
  );

  /// The detail for a device; phones are told apart by the browser
  /// (`Browser.isPhone`), not by the scene.
  static GalleryDetail forDevice({required bool phone}) =>
      phone ? GalleryDetail.phone : full;

  /// flutter_scene's render scale: the fraction of the view's physical size
  /// the scene is rendered at before it is scaled up to fill it.
  final double renderScale;

  /// Whether the lamps' pools are baked into the surfaces at load instead of
  /// shaded live (LightmapBake). Live, every pixel loops over every lamp
  /// that reaches its surface; baked, no lamp is hung at all.
  final bool bakeLighting;
}
