import 'dart:ui' as ui;

import 'package:portfolio/presentation/gallery/build_timing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';
import 'package:portfolio/presentation/gallery/build_yield.dart';

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
    required this.roughMetal,
    required this.unitsPerRepeat,
    required this.metallic,
    this.normal,
    this.occlusion,
    this.packedFrom,
  });

  /// Base colour. sRGB.
  final String colour;

  /// Roughness in green and metalness in blue, the channels the shader
  /// reads, loaded as it is (PORTFOLIO-8: nothing is repacked in the
  /// browser any more).
  ///
  /// Either the set's own grey roughness map, for a dielectric: every
  /// channel holds roughness, and a [metallic] of 0 zeroes whatever blue
  /// carries. Or a map packed ahead of time by `tool/pack_rough_metal.py`
  /// from [packedFrom], for anything with metal in it.
  final String roughMetal;

  /// Tangent-space normals in **OpenGL** convention (green up).
  ///
  /// A set shipping both conventions also ships a DirectX variant with green
  /// inverted; using it lights every bump from the wrong side, which reads as
  /// the surface being subtly inside-out rather than as an obvious error.
  final String? normal;

  /// Baked ambient occlusion — contact shadow in the crevices, which no
  /// runtime light in this scene is going to produce.
  final String? occlusion;

  /// What [roughMetal] was packed from, when it was packed: the grey
  /// roughness map, the metalness map if the set has one, and the metallic
  /// written into every texel where it does not.
  ///
  /// A metalness map is usually absent, and rightly: most of these downloads
  /// ship a uniform one as a placeholder, which says in a megabyte what a
  /// number says. Worth packing only when it is measured to vary — the
  /// keycap metals average 0.51, 0.57 and 0.86 across their faces rather
  /// than sitting at one value, and a scalar would flatten exactly the
  /// patina that makes them look like three different alloys.
  ///
  /// Not read at runtime. The packing test checks the packed file against
  /// these sources, so the two cannot drift.
  final PackedFrom? packedFrom;

  /// World units spanned by one repeat.
  final double unitsPerRepeat;

  /// The material's metallic factor, which scales [roughMetal]'s blue: 0
  /// for a dielectric loaded from its grey roughness map, 1 for a packed map
  /// whose blue is the metalness itself.
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

/// The sources a [TextureSet.roughMetal] map was packed from.
class PackedFrom {
  const PackedFrom({
    required this.roughness,
    required this.metallic,
    this.metalness,
  });

  /// Greyscale roughness, written to green.
  final String roughness;

  /// Where the surface is metal, written to blue; null for [metallic].
  final String? metalness;

  /// Written to blue in every texel when there is no [metalness] map.
  final double metallic;
}

/// The photographed sets the gallery is surfaced with.
abstract final class GallerySurfaces {
  /// ambientCG `Tiles013`. No baked occlusion, and no `Metalness` map —
  /// which is its own answer: glazed tile is dielectric.
  ///
  /// Its roughness runs 64..255 with a mean of 92/255, which sits in the
  /// middle of everything tried here: the tile before it averaged 22 and was
  /// close to a mirror, the wood before that 135 and was flat. That matters
  /// more than it sounds, because the renderer has no screen-space
  /// reflections — a near-mirror floor cannot show the corridor back, only a
  /// wash of the constant environment, so it reads as glare rather than as
  /// polish. Semi-matte is the range where a floor still looks like stone.
  static const TextureSet floor = TextureSet(
    colour: 'assets/textures/floor/Tiles013_1K-JPG_Color.webp',
    roughMetal: 'assets/textures/floor/Tiles013_1K-JPG_Roughness.webp',
    normal: 'assets/textures/floor/Tiles013_1K-JPG_NormalGL.webp',
    unitsPerRepeat: 4,
    metallic: 0,
  );

  /// ambientCG `Marble004`. No baked occlusion in this one.
  ///
  /// A longer repeat than the brick it replaced, and for a reason particular
  /// to the material: brick is a regular grid, so a repeat boundary hides
  /// inside the pattern, while marble is veining — a shape the eye tracks and
  /// recognises. Tiled as tightly as brick, the same vein reappears every two
  /// units and the wall reads as wallpaper.
  static const TextureSet wall = TextureSet(
    colour: 'assets/textures/wall/Marble004_1K-JPG_Color.webp',
    roughMetal: 'assets/textures/wall/Marble004_1K-JPG_Roughness.webp',
    normal: 'assets/textures/wall/Marble004_1K-JPG_NormalGL.webp',
    unitsPerRepeat: 4,
    // Stone is dielectric. The polish comes from the roughness map, not from
    // metallic, which would tint the highlight with the marble's own colour.
    metallic: 0,
  );

  /// ambientCG `Wood066`, for the frames the work hangs in.
  ///
  /// A much shorter repeat than any wall: a frame moulding is a few
  /// centimetres across, and grain tiled at wall scale would stretch a single
  /// board over the whole frame and read as a photograph of wood rather than
  /// as wood.
  static const TextureSet frame = TextureSet(
    colour: 'assets/textures/frame/Wood066_1K-JPG_Color.webp',
    roughMetal: 'assets/textures/frame/Wood066_1K-JPG_Roughness.webp',
    normal: 'assets/textures/frame/Wood066_1K-JPG_NormalGL.webp',
    unitsPerRepeat: 0.6,
    metallic: 0,
  );

  /// ambientCG `Wood020`, for the frames on the far wall.
  ///
  /// A different wood from the corridor's on purpose. The far wall is a
  /// different room in all but name — a bay off the main run — and giving it
  /// its own timber says so before any label does. Same short repeat, for the
  /// same reason: a moulding is centimetres across.
  static const TextureSet testimonialFrame = TextureSet(
    colour: 'assets/textures/frame_testimonials/Wood020_1K-JPG_Color.webp',
    roughMetal:
        'assets/textures/frame_testimonials/Wood020_1K-JPG_Roughness.webp',
    normal: 'assets/textures/frame_testimonials/Wood020_1K-JPG_NormalGL.webp',
    unitsPerRepeat: 0.6,
    metallic: 0,
  );

  /// ambientCG `Metal048B`, for the keyboard's case.
  ///
  /// A long repeat, because the case is a single milled block: seeing the
  /// pattern twice across it reads as a wrap rather than as the material.
  ///
  /// Its `Metalness` map is not listed — measured at 199..255 with a mean of
  /// 254.7, so it is white but for a scatter, which [metallic] says in one
  /// number. Its roughness is what earns its place: a mean of 37/255 makes
  /// this the most polished thing in the gallery, which is right for the one
  /// manufactured object in a room full of plaster and timber.
  static const TextureSet keyboardBase = TextureSet(
    colour: 'assets/textures/keyboard_base/Metal048B_1K-JPG_Color.webp',
    roughMetal: 'assets/textures/keyboard_base/Metal048B_1K-JPG_RoughMetal.webp',
    packedFrom: PackedFrom(
      roughness: 'assets/textures/keyboard_base/Metal048B_1K-JPG_Roughness.webp',
      metallic: 1,
    ),
    normal: 'assets/textures/keyboard_base/Metal048B_1K-JPG_NormalGL.webp',
    unitsPerRepeat: 2.5,
    metallic: 1,
  );

  /// The three metals the keycap rows are cut from.
  ///
  /// One per row, cycled — there are four rows and three sets, so the last
  /// row repeats the first. Different alloys per row is doing the job the
  /// original's row tints did: telling the eye at a glance that the board is
  /// grouped, without a label on it.
  ///
  /// All three bind their metalness maps, unlike every other set here, and
  /// for a measured reason: they vary across the face rather than sitting at
  /// one value.
  static const List<TextureSet> keyRows = <TextureSet>[
    TextureSet(
      colour: 'assets/textures/keys/set_1/Metal023_1K-JPG_Color.webp',
      roughMetal: 'assets/textures/keys/set_1/Metal023_1K-JPG_RoughMetal.webp',
      normal: 'assets/textures/keys/set_1/Metal023_1K-JPG_NormalGL.webp',
      packedFrom: PackedFrom(
        roughness: 'assets/textures/keys/set_1/Metal023_1K-JPG_Roughness.webp',
        metalness: 'assets/textures/keys/set_1/Metal023_1K-JPG_Metalness.webp',
        metallic: 1,
      ),
      // One repeat across a cap: the cap is the size of the detail, so
      // anything longer shows a single flat patch of it.
      unitsPerRepeat: 0.4,
      metallic: 1,
    ),
    TextureSet(
      colour: 'assets/textures/keys/set_2/Metal056B_1K-JPG_Color.webp',
      roughMetal: 'assets/textures/keys/set_2/Metal056B_1K-JPG_RoughMetal.webp',
      normal: 'assets/textures/keys/set_2/Metal056B_1K-JPG_NormalGL.webp',
      packedFrom: PackedFrom(
        roughness: 'assets/textures/keys/set_2/Metal056B_1K-JPG_Roughness.webp',
        metalness: 'assets/textures/keys/set_2/Metal056B_1K-JPG_Metalness.webp',
        metallic: 1,
      ),
      unitsPerRepeat: 0.4,
      metallic: 1,
    ),
    TextureSet(
      colour: 'assets/textures/keys/set_3/Metal022_1K-JPG_Color.webp',
      roughMetal: 'assets/textures/keys/set_3/Metal022_1K-JPG_RoughMetal.webp',
      normal: 'assets/textures/keys/set_3/Metal022_1K-JPG_NormalGL.webp',
      packedFrom: PackedFrom(
        roughness: 'assets/textures/keys/set_3/Metal022_1K-JPG_Roughness.webp',
        metalness: 'assets/textures/keys/set_3/Metal022_1K-JPG_Metalness.webp',
        metallic: 1,
      ),
      unitsPerRepeat: 0.4,
      metallic: 1,
    ),
  ];

  /// ambientCG `OfficeCeiling001`.
  ///
  /// The download also carries `Emission` and `Metalness` maps, and neither
  /// is listed: the two files are byte-identical to each other and uniform,
  /// which is what ambientCG ships as a placeholder for a map the material
  /// does not really have. An emissive map of solid black would light
  /// nothing, and a metalness map of solid black is what [metallic] already
  /// says — so both would cost a decode and an upload to change nothing.
  static const TextureSet ceiling = TextureSet(
    colour: 'assets/textures/roof/OfficeCeiling001_1K-JPG_Color.webp',
    roughMetal: 'assets/textures/roof/OfficeCeiling001_1K-JPG_Roughness.webp',
    normal: 'assets/textures/roof/OfficeCeiling001_1K-JPG_NormalGL.webp',
    occlusion:
        'assets/textures/roof/OfficeCeiling001_1K-JPG_AmbientOcclusion.webp',
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
    await BuildYield.frame();
    await onStep?.call();
    final roughness = await decodeMap(set.roughMetal);
    await BuildYield.frame();
    await onStep?.call();
    if (colour == null || roughness == null) {
      colour?.dispose();
      roughness?.dispose();
      return null;
    }

    final normal = set.normal == null ? null : await decodeMap(set.normal!);
    await BuildYield.frame();
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

    final colourTexture = await BuildTiming.span(BuildPhase.upload, () => Texture2D.fromImage(colour));
    await BuildYield.frame();
    await onStep?.call();
    // Linear data, not colour. Decoded as sRGB these would be averaged in the
    // wrong space down the mip chain, so roughness and occlusion would drift
    // with distance; normals are averaged as vectors and renormalised.
    final roughnessTexture = await BuildTiming.span(BuildPhase.upload, () => Texture2D.fromImage(
      roughness,
      content: TextureContent.data,
    ));
    await BuildYield.frame();
    await onStep?.call();
    final normalTexture = normal == null
        ? null
        : await BuildTiming.span(BuildPhase.upload, () => Texture2D.fromImage(normal, content: TextureContent.normal));
    await BuildYield.frame();
    if (normalTexture != null) await onStep?.call();
    final occlusionTexture = occlusion == null
        ? null
        : await BuildTiming.span(BuildPhase.upload, () => Texture2D.fromImage(occlusion, content: TextureContent.data));
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
      ..metallicFactor = set.metallic;

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

  /// Decodes one map, or null if it is undeclared or unreadable.
  ///
  /// Public, and no longer only for tests: the room's lettering is painted
  /// with a photograph that never reaches the GPU — it is a brush, not a
  /// texture — so it wants the decoding half of this and nothing else.
  ///
  /// Null rather than throwing. A missing map is a surface that falls back,
  /// and none of them is worth failing a whole room over.
  static Future<ui.Image?> decodeMap(String asset) async {
    try {
      final data = await BuildTiming.span(
        BuildPhase.fetch,
        () => rootBundle.load(asset),
      );
      return await BuildTiming.span(BuildPhase.decode, () async {
        final codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(),
          targetWidth: resolution,
          targetHeight: resolution,
        );
        final frame = await codec.getNextFrame();
        codec.dispose();
        return frame.image;
      });
    } catch (_) {
      return null;
    }
  }
}
