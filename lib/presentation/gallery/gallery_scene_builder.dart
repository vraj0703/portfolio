import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter/widgets.dart' show TextSpan;
import 'package:portfolio/domain/gallery/gallery_dimensions.dart';
import 'package:flutter_scene/scene.dart';
// vector_math, not Flutter's re-export of vector_math_64: flutter_scene works
// in 32-bit vectors throughout, and the two Matrix4 types are unrelated as far
// as the analyser is concerned.
import 'package:vector_math/vector_math.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';
import 'package:portfolio/domain/gallery/gallery_lighting.dart';
import 'package:portfolio/presentation/gallery/scene_axes.dart';
import 'package:portfolio/presentation/gallery/control_icons.dart';
import 'package:portfolio/presentation/gallery/scroll_arrow.dart';
import 'package:portfolio/presentation/gallery/surface_textures.dart';
import 'package:portfolio/domain/style/text_styles.dart';
import 'package:portfolio/presentation/gallery/wall_text.dart';
import 'package:portfolio/presentation/gallery/texture_sets.dart';

/// Builds the gallery's scene graph, and owns everything it allocates.
///
/// Separated from the widget that displays it because construction is
/// asynchronous and the GPU resources it creates have to be released
/// deliberately — textures and images are not garbage collected. Anything
/// this builder makes, it also disposes.
class GalleryScene {
  GalleryScene._(
    this.scene,
    this.arrow,
    this.controls,
    this._artwork,
    this._textures,
  );

  final Scene scene;

  /// The entrance cue, exposed so the view can advance its bob and retire it.
  /// Null when the model could not be read — see [ScrollArrow.load].
  final ScrollArrow? arrow;

  /// The three controls that appear under a focused piece, as objects in the
  /// room. Null when their models could not be read.
  final ControlIcons? controls;

  /// Rasterised project art. Owned here, not by the materials that sample it:
  /// a material holding the only reference to an image has no moment at which
  /// it can be told to let go.
  final List<ui.Image> _artwork;
  final List<Texture2D> _textures;

  bool _disposed = false;

  /// The build in flight, or the finished one.
  ///
  /// Memoised so the scene can be started before it is needed and simply
  /// awaited when it is. See [warmUp].
  static Future<GalleryScene>? _pending;

  /// The finished gallery, if it has already been built.
  ///
  /// Exists so a view arriving after the warm-up can take it *synchronously*.
  /// Awaiting a future that has already completed still costs a frame, and
  /// that frame is a flat placeholder standing between the previous stage and
  /// the corridor — a visible seam in an otherwise continuous move.
  static GalleryScene? get ready => _ready;
  static GalleryScene? _ready;

  /// Starts building the gallery ahead of time.
  ///
  /// Assembling it means rasterising a canvas per project and uploading each
  /// as a texture — seconds of work on a slow machine. Left until the visitor
  /// arrives, that time is spent staring at an empty screen, because the
  /// stage they just finished has already been torn down.
  ///
  /// Idempotent: calling it repeatedly returns the same build, and only the
  /// first caller's [onProgress] is honoured — later callers are joining work
  /// already underway, not starting their own.
  static Future<GalleryScene> warmUp({
    int artworkSize = 1024,
    void Function(double)? onProgress,
  }) => _pending ??= build(artworkSize: artworkSize, onProgress: onProgress);

  /// Assembles the corridor and everything hanging in it.
  ///
  /// [artworkSize] is the edge length of each project's rasterised art. Lower
  /// it in tests: the default is sized for a full-screen frame and rasterising
  /// seven of them is the slowest part of opening the gallery.
  static Future<GalleryScene> build({
    int artworkSize = 1024,
    void Function(double)? onProgress,
  }) async {
    // Geometry and materials touch the shader bundle, so nothing can be
    // constructed before the engine's static resources exist.
    await Scene.initializeStaticResources();
    await _report(onProgress, _shaderShare);

    final scene = Scene()
      // Replaces the engine's default studio environment. That default is
      // built to flatter a product on a turntable; this is a dim room, and
      // what it needs from its ambient term is the original's flat warm wash,
      // not a photographic key and rim.
      ..environment = EnvironmentMap.constantDiffuse(GalleryLighting.ambient);
    final artwork = <ui.Image>[];
    final textures = <Texture2D>[];

    await _populate(scene, artwork, textures, artworkSize, onProgress);
    _light(scene);
    await _hangStatement(scene, artwork, textures);

    final arrow = await ScrollArrow.load();
    if (arrow != null) scene.add(arrow.node);

    final controls = await ControlIcons.load();
    if (controls != null) scene.add(controls.node);

    await _report(onProgress, 1);

    return _ready = GalleryScene._(scene, arrow, controls, artwork, textures);
  }

  /// Reports [value] and hands a frame back to the engine.
  ///
  /// Every expensive thing in this build — decoding, repacking, mip-chain
  /// construction, canvas rasterisation — runs on the main isolate. Reporting
  /// progress in the middle of that does not make the bar move: nothing can
  /// paint while the thread is held, so the reports pile up and the bar sits
  /// frozen on whatever it last drew until the whole phase finishes and the
  /// backlog arrives in one frame. That is the stall, and no amount of finer
  /// reporting fixes it — it only changes which number it freezes on.
  ///
  /// Waiting for the end of a frame costs about sixteen milliseconds a step.
  /// A loading bar that moves is worth more than the half-second.
  static Future<void> _report(
    void Function(double)? onProgress,
    double value,
  ) async {
    onProgress?.call(value);
    if (onProgress == null) return;
    await SchedulerBinding.instance.endOfFrame;
  }

  /// Share of the build spent bringing the shader bundle up, before any
  /// artwork exists to report against.
  static const double _shaderShare = 0.15;

  /// Where the bar stands once the photographed surfaces are in.
  ///
  /// The bulk of the bar, because it is the bulk of the time: ten JPEG
  /// decodes, three million-pixel repacks and ten mipmapped uploads, against
  /// seven canvas draws for the artwork. Sharing the bar evenly between them
  /// would make it crawl through this and then sprint, which reads as a stall
  /// followed by a jump — the same complaint, moved rather than fixed.
  static const double _surfaceShare = 0.8;

  /// Walks the layout and creates a node for each piece.
  ///
  /// No decisions here: where things go is [GalleryLayout]'s business, which
  /// is what lets it be tested without a GPU.
  static Future<void> _populate(
    Scene scene,
    List<ui.Image> artwork,
    List<Texture2D> textures,
    int artworkSize,
    void Function(double)? onProgress,
  ) async {
    // Built once and shared by every wall. Each surface having its own copy
    // would multiply an identical megabyte of noise by the number of walls.
    final normal = await SurfaceTextures.normalMap();
    final rough = await SurfaceTextures.metallicRoughnessMap();
    artwork
      ..add(normal)
      ..add(rough);

    final normalTexture = await Texture2D.fromImage(
      normal,
      content: TextureContent.normal,
    );
    final roughTexture = await Texture2D.fromImage(
      rough,
      content: TextureContent.data,
    );
    textures
      ..add(normalTexture)
      ..add(roughTexture);

    // Photographed rather than generated. Each is null when its files cannot
    // be read, which drops that surface back to the procedural plaster
    // instead of failing the whole room.
    const sets = <SurfaceKind, TextureSet>{
      SurfaceKind.floor: GallerySurfaces.floor,
      SurfaceKind.ceiling: GallerySurfaces.ceiling,
      SurfaceKind.sideWall: GallerySurfaces.wall,
      SurfaceKind.frame: GallerySurfaces.frame,
    };

    final totalSteps = sets.values.fold<int>(0, (sum, s) => sum + s.stepCount);
    var stepsDone = 0;

    final surfaces = <SurfaceKind, SurfaceMaps?>{};
    for (final entry in sets.entries) {
      surfaces[entry.key] = await SurfaceMaps.load(
        entry.value,
        artwork,
        textures,
        onStep: () async {
          stepsDone++;
          await _report(
            onProgress,
            _shaderShare +
                (_surfaceShare - _shaderShare) * (stepsDone / totalSteps),
          );
        },
      );
    }

    final pieces = GalleryLayout.build();
    for (final piece in pieces) {
      // Design space in, engine space out — see [SceneAxes]. Position and
      // rotation have to cross together; flipping one without the other
      // leaves every frame facing into its own wall.
      final transform = Matrix4.translation(SceneAxes.position(piece.position));
      if (piece.rotationY != 0) {
        transform.rotateY(SceneAxes.rotationY(piece.rotationY));
      }

      if (piece.kind == SurfaceKind.exitSign) {
        await _paintExitSign(scene, piece, artwork, textures, transform);
        continue;
      }

      if (piece.kind == SurfaceKind.frame) {
        _hangFrame(scene, piece, surfaces[SurfaceKind.frame], transform);
        continue;
      }

      final material = _surfaceOf(piece, normalTexture, roughTexture, surfaces);

      final geometry = switch (piece.kind) {
        // The floor alone is a plane. A plane's normals point straight up,
        // which is what a floor wants and what a ceiling cannot use — see
        // [GalleryLayout.ceilingThickness].
        SurfaceKind.floor => PlaneGeometry(
          width: piece.extents.x,
          depth: piece.extents.z,
        ),
        _ => CuboidGeometry(piece.extents),
      };

      scene.add(
        Node(mesh: Mesh(geometry, material), localTransform: transform),
      );
    }
  }

  /// Hangs the lights described by [GalleryLighting].
  ///
  /// A spot's aim is its node's business, not the light's: the direction is
  /// given in local space and rotated by the node's transform, so each light
  /// is placed by translation and aimed by the direction it carries.
  static void _light(Scene scene) {
    for (final light in GalleryLighting.build()) {
      final colour = Vector3(light.colour.r, light.colour.g, light.colour.b);

      final node = Node(
        localTransform: Matrix4.translation(SceneAxes.position(light.position)),
      );

      switch (light.kind) {
        case LightKind.spot:
          node.addComponent(
            SpotLightComponent(
              SpotLight(
                color: colour,
                intensity: light.intensity,
                range: light.range,
                direction: SceneAxes.position(light.direction!),
                innerConeAngle: light.innerCone,
                outerConeAngle: light.outerCone,
              ),
            ),
          );
        case LightKind.point:
          node.addComponent(
            PointLightComponent(
              PointLight(
                color: colour,
                intensity: light.intensity,
                range: light.range,
              ),
            ),
          );
      }

      scene.add(node);
    }
  }

  /// The name and statement on the far wall.
  ///
  /// The end of the corridor has to be a destination rather than the point
  /// at which the work runs out; a blank wall there reads as an unfinished
  /// room. Baked to a texture rather than mounted as a live widget surface —
  /// see [WallText].
  static Future<void> _hangStatement(
    Scene scene,
    List<ui.Image> images,
    List<Texture2D> textures,
  ) async {
    const type = DefaultAppTypography();
    const width = 1600;
    const height = 640;

    final image = await WallText.render(
      width: width,
      height: height,
      lines: <TextSpan>[
        TextSpan(text: 'VISHAL RAJ\n', style: type.wallName),
        TextSpan(
          text:
              '\n'
              'I make software that works quietly and well. For a decade I '
              'have been building mobile apps, developer tools, and lately '
              'AI systems that can think for themselves. Good engineering is '
              'invisible — you only notice it when it is missing.',
          style: type.wallStatement,
        ),
      ],
      rulePosition: 178,
      ruleColour: DefaultAppTypography.wallInk,
      ruleWidth: 480,
    );
    images.add(image);

    final texture = await Texture2D.fromImage(image);
    textures.add(texture);

    // Sized from the image's own proportions, so retyping the statement
    // cannot silently stretch it.
    const worldWidth = 6.0;
    const worldHeight = worldWidth * height / width;

    scene.add(
      Node(
        mesh: Mesh(
          CuboidGeometry(Vector3(worldWidth, worldHeight, 0.02)),
          _neon(texture),
        ),
        localTransform: Matrix4.translation(
          SceneAxes.position(
            Vector3(
              0,
              0.9,
              // Clear of the slab, not merely nudged toward the room: the
              // wall is 0.2 thick and centred on this plane, so a smaller
              // offset leaves the lettering buried inside it.
              GalleryDimensions.backWallZ + GalleryLayout.paintedOnWall,
            ),
          ),
        ),
      ),
    );
  }

  /// A lit sign on a wall: unlit shading, alpha blended.
  ///
  /// Both halves matter. **Unlit**, because the corridor is deliberately dim
  /// and a lit material would leave the lettering as dark as the plaster it
  /// sits on — the glow has to come from the sign, not from the room.
  /// **Blended**, because the texture is transparent apart from the letters,
  /// and an opaque material ignores alpha: the cleared background rasterises
  /// as solid black and the sign arrives as a black slab. That is exactly
  /// what was on the wall.
  static UnlitMaterial _neon(Texture2D texture) =>
      UnlitMaterial(colorTexture: texture)..alphaMode = AlphaMode.blend;

  /// Paints the way out onto the wall it belongs to.
  ///
  /// On the wall rather than floating over the view, so it tilts with the
  /// corridor and reads as part of the room — lettering on plaster, not a
  /// button on a page.
  static Future<void> _paintExitSign(
    Scene scene,
    Placement piece,
    List<ui.Image> images,
    List<Texture2D> textures,
    Matrix4 transform,
  ) async {
    const type = DefaultAppTypography();
    const width = 680;
    const height = 248;

    final image = await WallText.render(
      width: width,
      height: height,
      lines: <TextSpan>[
        // No arrow and no plate: the visitor asked for lettering on plaster,
        // and a glyph plus a border is a button drawn on a wall rather than
        // a word written on one.
        TextSpan(text: 'BACK', style: type.wallSign),
      ],
      rulePosition: 172,
      ruleColour: DefaultAppTypography.wallInk,
      ruleWidth: 300,
    );
    images.add(image);

    final texture = await Texture2D.fromImage(image);
    textures.add(texture);

    scene.add(
      Node(
        mesh: Mesh(CuboidGeometry(piece.extents), _neon(texture)),
        localTransform: transform,
      ),
    );
  }

  /// Hangs one piece: the wooden frame, and the card inside it.
  ///
  /// Two meshes rather than one. The frame is a moulding with its own
  /// material and the card is a flat surface with another, and a single box
  /// carrying one texture cannot be both — which is what made the old frames
  /// read as printed panels rather than as work in a frame.
  static void _hangFrame(
    Scene scene,
    Placement piece,
    SurfaceMaps? wood,
    Matrix4 transform,
  ) {
    final width = GalleryLayout.frameWidth;
    final height = piece.extents.y;
    final depth = piece.extents.z;

    scene.add(
      Node(
        mesh: Mesh(
          CuboidGeometry(Vector3(width, height, depth)),
          wood?.materialFor(width, height) ??
              _material(const ui.Color(0xFF6B4A2F), 0.7, 0),
        ),
        localTransform: transform,
      ),
    );

    // Blank on purpose, for now — the card is the surface the work will be
    // presented on, and an empty one states the shape of the room without
    // pretending to content it does not have yet.
    final card = Matrix4.copy(transform)
      ..translateByDouble(0, 0, depth / 2 + GalleryLayout.cardRelief, 1);

    scene.add(
      Node(
        mesh: Mesh(
          CuboidGeometry(
            Vector3(
              width - GalleryLayout.frameBorder * 2,
              height - GalleryLayout.frameBorder * 2,
              GalleryLayout.cardRelief * 2,
            ),
          ),
          // Lifted slightly by its own emission. A matte white card under a
          // picture light this dim otherwise settles to grey, and a gallery
          // card that reads as grey reads as unlit rather than as blank.
          _material(const ui.Color(0xFFFFFFFF), 0.92, 0)
            ..emissiveFactor = Vector4(0.06, 0.06, 0.055, 1),
        ),
        localTransform: card,
      ),
    );
  }

  static PhysicallyBasedMaterial _surfaceOf(
    Placement piece,
    Texture2D normal,
    Texture2D rough,
    Map<SurfaceKind, SurfaceMaps?> surfaces,
  ) {
    // Every wall draws on the one set, whichever wall it is — a room whose
    // back wall is a different brick from its side walls does not read as a
    // room that was built, only as one that was assembled.
    final kind = switch (piece.kind) {
      SurfaceKind.floor || SurfaceKind.ceiling => piece.kind,
      _ => SurfaceKind.sideWall,
    };

    final (across, down) = _spanOf(piece);
    final maps = surfaces[kind];
    if (maps != null) return maps.materialFor(across, down);

    // Nothing loaded, so fall back to what the room looked like before there
    // were photographs of one: flat colour, and procedural plaster on the
    // walls where a raking light has something to catch.
    if (kind != SurfaceKind.sideWall) {
      return switch (kind) {
        SurfaceKind.floor => _material(const ui.Color(0xFF8A7A62), 0.85, 0.05),
        _ => _material(const ui.Color(0xFFD9C7B8), 0.5, 0),
      };
    }

    final tiling = Vector2(
      SurfaceTextures.repeatsFor(across),
      SurfaceTextures.repeatsFor(down),
    );

    return _material(const ui.Color(0xFFD4A97E), 0.75, 0.08)
      ..normalTexture = normal
      ..normalTextureTransform = TextureTransform(scale: tiling)
      ..metallicRoughnessTexture = rough
      ..metallicRoughnessTextureTransform = TextureTransform(scale: tiling);
  }

  /// The two axes a surface actually spans, in world units.
  ///
  /// A wall's *thickness* is not one of them: tiling by a 0.2-unit axis would
  /// put a single repeat across the whole face and smear it up the wall.
  static (double, double) _spanOf(Placement piece) {
    final e = piece.extents;
    return switch (piece.kind) {
      SurfaceKind.floor || SurfaceKind.ceiling => (e.x, e.z),
      // Side walls run along z; the back and wing walls run along x.
      SurfaceKind.sideWall => (e.z, e.y),
      _ => (e.x, e.y),
    };
  }

  /* -- Helpers --------------------------------------------------------- */

  static PhysicallyBasedMaterial _material(
    ui.Color colour,
    double roughness,
    double metallic,
  ) {
    return PhysicallyBasedMaterial()
      ..baseColorFactor = Vector4(colour.r, colour.g, colour.b, 1)
      ..roughnessFactor = roughness
      ..metallicFactor = metallic;
  }

  /// Releases every GPU resource the build allocated.
  ///
  /// Safe to call twice — a view can be disposed while a rebuild is still in
  /// flight, and the second call should be a no-op rather than a crash.
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    // Drop both handles alongside the resources they refer to. Leaving either
    // would hand the next visitor a scene whose textures have been freed.
    _pending = null;
    _ready = null;

    for (final image in _artwork) {
      image.dispose();
    }
    _artwork.clear();
    _textures.clear();
  }
}
