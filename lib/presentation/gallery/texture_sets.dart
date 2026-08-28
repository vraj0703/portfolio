import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';

/// A photographed material: which files it is made of, and how big it is.
///
/// Only the maps the renderer can actually consume are named. Two kinds of
/// file in these downloads are silently useless and must not be listed:
///
///  * **OpenEXR normal maps.** Flutter's image codec decodes PNG, JPEG, WebP,
///    GIF and BMP. There is no EXR path, so an `.exr` cannot be loaded at all
///    — which is why some sets here have a normal map and some do not.
///  * **Displacement/height maps.** The material's slots are base colour,
///    metallic-roughness, normal, emissive, occlusion and lightmap. Height is
///    not among them, and nothing in this scene tessellates.
class TextureSet {
  const TextureSet({
    required this.colour,
    required this.roughness,
    required this.unitsPerRepeat,
    this.normal,
    this.occlusion,
    this.metallic = 0.05,
  });

  /// Base colour. sRGB.
  final String colour;

  /// Greyscale roughness, repacked on load — see [SurfaceMaps.load].
  final String roughness;

  /// Tangent-space normals in **OpenGL** convention (green up).
  ///
  /// A set shipping both conventions also ships a DirectX variant with green
  /// inverted; using it lights every bump from the wrong side, which reads as
  /// the surface being subtly inside-out rather than as an obvious error.
  final String? normal;

  /// Baked ambient occlusion — contact shadow in the crevices, which no
  /// runtime light in this scene is going to produce.
  final String? occlusion;

  /// World units spanned by one repeat.
  final double unitsPerRepeat;

  /// Metallic written into every texel. These are all dielectric.
  final double metallic;

  /// How many files this set is made of.
  int get mapCount =>
      2 + (normal == null ? 0 : 1) + (occlusion == null ? 0 : 1);

  /// Units of work loading this set reports.
  ///
  /// Two per file, because each is decoded and then uploaded, and the upload
  /// is not the cheap half — it builds a full mip chain for a 1024² texture.
  /// Counting only the decodes left the bar silent through every upload,
  /// which is what made it stall with the work still running.
  ///
  /// The bar needs this *before* the work starts, to have a denominator.
  int get stepCount => mapCount * 2;
}

/// The photographed sets the gallery is surfaced with.
abstract final class GallerySurfaces {
  /// ambientCG `Tiles079`. No baked occlusion in this one.
  static const TextureSet floor = TextureSet(
    colour: 'assets/textures/floor/Tiles079_1K-JPG_Color.jpg',
    roughness: 'assets/textures/floor/Tiles079_1K-JPG_Roughness.jpg',
    normal: 'assets/textures/floor/Tiles079_1K-JPG_NormalGL.jpg',
    unitsPerRepeat: 4,
  );

  /// ambientCG `Marble004`. No baked occlusion in this one.
  ///
  /// A longer repeat than the brick it replaced, and for a reason particular
  /// to the material: brick is a regular grid, so a repeat boundary hides
  /// inside the pattern, while marble is veining — a shape the eye tracks and
  /// recognises. Tiled as tightly as brick, the same vein reappears every two
  /// units and the wall reads as wallpaper.
  static const TextureSet wall = TextureSet(
    colour: 'assets/textures/wall/Marble004_1K-JPG_Color.jpg',
    roughness: 'assets/textures/wall/Marble004_1K-JPG_Roughness.jpg',
    normal: 'assets/textures/wall/Marble004_1K-JPG_NormalGL.jpg',
    unitsPerRepeat: 4,
    // Stone is dielectric. The polish comes from the roughness map, not from
    // metallic, which would tint the highlight with the marble's own colour.
    metallic: 0,
  );

  /// ambientCG `OfficeCeiling001`.
  ///
  /// The download also carries `Emission` and `Metalness` maps, and neither
  /// is listed: the two files are byte-identical to each other and uniform,
  /// which is what ambientCG ships as a placeholder for a map the material
  /// does not really have. An emissive map of solid black would light
  /// nothing, and a metalness map of solid black is what [metallic] already
  /// says — so both would cost a decode and an upload to change nothing.
  static const TextureSet ceiling = TextureSet(
    colour: 'assets/textures/roof/OfficeCeiling001_1K-JPG_Color.jpg',
    roughness: 'assets/textures/roof/OfficeCeiling001_1K-JPG_Roughness.jpg',
    normal: 'assets/textures/roof/OfficeCeiling001_1K-JPG_NormalGL.jpg',
    occlusion:
        'assets/textures/roof/OfficeCeiling001_1K-JPG_AmbientOcclusion.jpg',
    // Panels rather than a plaster field, so a shorter repeat: at four units
    // a single panel would be wider than half the corridor.
    unitsPerRepeat: 2,
    metallic: 0,
  );
}

/// One set, decoded and uploaded.
class SurfaceMaps {
  const SurfaceMaps._(
    this.set,
    this.colour,
    this.roughness,
    this.normal,
    this.occlusion,
  );

  final TextureSet set;
  final Texture2D colour;
  final Texture2D roughness;
  final Texture2D? normal;
  final Texture2D? occlusion;

  /// Edge length every map is decoded to, whatever it is stored at.
  ///
  /// The sources are 4K, and 4K is not a size these can be used at: decoded
  /// to RGBA one map is 67MB before its mip chain, and the room needs eight.
  /// Downsampling *at* decode rather than after means the full resolution
  /// never exists in memory at all.
  static const int resolution = 1024;

  /// Decodes and uploads [set], or returns null if any of it cannot be read.
  ///
  /// Null rather than a throw: a surface falling back to flat colour is a
  /// worse-looking room, while a missing file taking the build down with it
  /// is no room at all.
  ///
  /// Everything allocated is appended to [images] and [textures], which the
  /// scene owns and disposes — a material holding the only reference to a
  /// texture has no moment at which it can be told to let go.
  /// [onStep] is awaited [TextureSet.stepCount] times: once as each file
  /// decodes, and once as each is uploaded.
  ///
  /// Awaited, not merely called, and that is the whole point. Decoding,
  /// repacking and uploading all run on the main isolate — `fromPixels` is
  /// synchronous, and builds an entire mip chain before it returns. Reporting
  /// progress without giving the engine a frame in between changes nothing
  /// the visitor can see: the reports queue up behind work that is holding
  /// the thread, the bar freezes on its last painted value, and the whole
  /// backlog lands at once when the thread is finally free. Handing back a
  /// frame between steps is what lets the bar actually move.
  static Future<SurfaceMaps?> load(
    TextureSet set,
    List<ui.Image> images,
    List<Texture2D> textures, {
    Future<void> Function()? onStep,
  }) async {
    final colour = await decodeMap(set.colour);
    await onStep?.call();
    final roughness = await packRoughness(set);
    await onStep?.call();
    if (colour == null || roughness == null) {
      colour?.dispose();
      roughness?.dispose();
      return null;
    }

    final normal = set.normal == null ? null : await decodeMap(set.normal!);
    if (set.normal != null) await onStep?.call();
    final occlusion = set.occlusion == null
        ? null
        : await decodeMap(set.occlusion!);
    if (set.occlusion != null) await onStep?.call();

    images
      ..add(colour)
      ..add(roughness);
    if (normal != null) images.add(normal);
    if (occlusion != null) images.add(occlusion);

    final colourTexture = await Texture2D.fromImage(colour);
    await onStep?.call();
    // Linear data, not colour. Decoded as sRGB these would be averaged in the
    // wrong space down the mip chain, so roughness and occlusion would drift
    // with distance; normals are averaged as vectors and renormalised.
    final roughnessTexture = await Texture2D.fromImage(
      roughness,
      content: TextureContent.data,
    );
    await onStep?.call();
    final normalTexture = normal == null
        ? null
        : await Texture2D.fromImage(normal, content: TextureContent.normal);
    if (normalTexture != null) await onStep?.call();
    final occlusionTexture = occlusion == null
        ? null
        : await Texture2D.fromImage(occlusion, content: TextureContent.data);
    if (occlusionTexture != null) await onStep?.call();

    textures
      ..add(colourTexture)
      ..add(roughnessTexture);
    if (normalTexture != null) textures.add(normalTexture);
    if (occlusionTexture != null) textures.add(occlusionTexture);

    return SurfaceMaps._(
      set,
      colourTexture,
      roughnessTexture,
      normalTexture,
      occlusionTexture,
    );
  }

  /// Builds the material, tiled to cover [across] by [down] world units.
  ///
  /// Both factors sit at 1 because they *multiply* the maps: the tint and
  /// roughness that stood in for a photograph would darken and flatten it
  /// rather than being replaced by it.
  PhysicallyBasedMaterial materialFor(double across, double down) {
    final tiling = TextureTransform(
      scale: Vector2(_repeats(across), _repeats(down)),
    );

    final material = PhysicallyBasedMaterial(baseColorTexture: colour)
      ..baseColorFactor = Vector4(1, 1, 1, 1)
      ..baseColorTextureTransform = tiling
      ..metallicRoughnessTexture = roughness
      ..metallicRoughnessTextureTransform = tiling
      ..roughnessFactor = 1
      ..metallicFactor = 1;

    final normalMap = normal;
    if (normalMap != null) {
      material
        ..normalTexture = normalMap
        ..normalTextureTransform = tiling;
    }

    final occlusionMap = occlusion;
    if (occlusionMap != null) {
      material
        ..occlusionTexture = occlusionMap
        ..occlusionTextureTransform = tiling;
    }

    return material;
  }

  double _repeats(double extent) =>
      (extent.abs() / set.unitsPerRepeat).clamp(1.0, 512.0);

  /// Repacks a greyscale roughness map the way the shader reads it.
  ///
  /// These sets store roughness as a grey image; the material wants a
  /// *metallic-roughness* map, where green carries roughness and blue carries
  /// metallic. Handing the grey image over unchanged writes **red**, which
  /// the shader ignores — leaving the surface uniformly glossy while looking
  /// entirely correct in an image viewer.
  @visibleForTesting
  static Future<ui.Image?> packRoughness(TextureSet set) async {
    final source = await decodeMap(set.roughness);
    if (source == null) return null;

    try {
      final grey = await source.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );
      if (grey == null) return null;

      final src = grey.buffer.asUint8List();
      final packed = Uint8List(src.length);
      final metallicByte = (set.metallic * 255).round().clamp(0, 255);

      for (var i = 0; i < src.length; i += 4) {
        packed[i] = 0;
        packed[i + 1] = src[i]; // grey, so any channel is the roughness
        packed[i + 2] = metallicByte;
        packed[i + 3] = 255;
      }

      // Awaited inside the `try`, so the source is not disposed out from
      // under a decode still in flight.
      return await _fromPixels(packed, source.width, source.height);
    } finally {
      source.dispose();
    }
  }

  /// Public for tests. The upload half needs a GPU context a test harness
  /// cannot provide, but decoding and packing are where the mistakes are.
  @visibleForTesting
  static Future<ui.Image?> decodeMap(String asset) async {
    try {
      final data = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: resolution,
        targetHeight: resolution,
      );
      final frame = await codec.getNextFrame();
      codec.dispose();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  static Future<ui.Image> _fromPixels(Uint8List pixels, int width, int height) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }
}
