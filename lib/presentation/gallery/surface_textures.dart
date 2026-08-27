import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Procedural surface detail for the gallery's plaster.
///
/// Ported from the React scene's generated maps. Without them every wall is a
/// single flat tone: with one normal across a whole surface there is nothing
/// for the picture lights to catch, so the geometry reads as bare polygons
/// rather than as a plastered room, and the corners are the only thing
/// telling you it has depth at all.
///
/// Generated rather than shipped. The maps are noise — an asset would be
/// hundreds of kilobytes to encode randomness that a loop produces in a few
/// milliseconds, and it would have to be authored at a fixed resolution.
abstract final class SurfaceTextures {
  /// Detail maps are tiled across each surface rather than stretched; at one
  /// repeat a 512px map spread over a thirty-metre wall is invisible.
  static const double tiling = 16;

  static const int _normalSize = 512;
  static const int _roughnessSize = 256;

  /// Fixed seed, so the walls look the same on every visit and between
  /// builds — a golden test over a randomly-textured room would never pass
  /// twice.
  static const int _seed = 0x5EED;

  /// Tangent-space normal map: a slow undulation with fine grain over it.
  ///
  /// The low-frequency sine gives the plaster its roll; the noise on top is
  /// what the raking picture lights actually pick out.
  static Future<ui.Image> normalMap() {
    const size = _normalSize;
    final pixels = Uint8List(size * size * 4);
    final random = math.Random(_seed);

    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final i = (y * size + x) * 4;

        // Centred on 128: that is "flat" in a tangent-space normal map, and
        // the deviation either side is the slope.
        pixels[i] = _clampByte(
          128 + (math.sin(x * 0.08) * math.cos(y * 0.05) * 15) +
              (random.nextDouble() - 0.5) * 12,
        );
        pixels[i + 1] = _clampByte(
          128 + (math.cos(x * 0.06) * math.sin(y * 0.09) * 15) +
              (random.nextDouble() - 0.5) * 12,
        );
        // Z stays high: these are shallow bumps, not a relief.
        pixels[i + 2] = _clampByte(230 + random.nextDouble() * 25);
        pixels[i + 3] = 255;
      }
    }

    return _decode(pixels, size);
  }

  /// Metallic-roughness map, packed the way the PBR shader reads it: green
  /// carries roughness, blue carries metallic.
  ///
  /// Worth stating because the source scene used a *separate* roughness map,
  /// and writing that straight into red here would produce a wall that is
  /// uniformly glossy while looking correct in an image viewer.
  static Future<ui.Image> metallicRoughnessMap({
    double metallic = 0.08,
  }) {
    const size = _roughnessSize;
    final pixels = Uint8List(size * size * 4);
    final random = math.Random(_seed ^ 0x1234);
    final metallicByte = _clampByte(metallic * 255);

    for (var i = 0; i < pixels.length; i += 4) {
      // Roughness wanders in a narrow band. Plaster is uniformly matte; the
      // variation is what stops the highlight from being a perfect gradient.
      final roughness = _clampByte(180 + random.nextDouble() * 50);

      pixels[i] = 0;
      pixels[i + 1] = roughness;
      pixels[i + 2] = metallicByte;
      pixels[i + 3] = 255;
    }

    return _decode(pixels, size);
  }

  static int _clampByte(double value) => value.round().clamp(0, 255);

  static Future<ui.Image> _decode(Uint8List pixels, int size) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      size,
      size,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }
}
