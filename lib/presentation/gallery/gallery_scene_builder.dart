import 'dart:ui' as ui;

import 'package:flutter/widgets.dart' show FontWeight, TextStyle;
import 'package:flutter_scene/scene.dart';
// vector_math, not Flutter's re-export of vector_math_64: flutter_scene works
// in 32-bit vectors throughout, and the two Matrix4 types are unrelated as far
// as the analyser is concerned.
import 'package:vector_math/vector_math.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';
import 'package:portfolio/domain/gallery/gallery_lighting.dart';
import 'package:portfolio/presentation/game/gallery/project_artwork.dart';
import 'package:portfolio/presentation/gallery/scene_axes.dart';
import 'package:portfolio/presentation/gallery/surface_textures.dart';
import 'package:portfolio/presentation/gallery/threshold_cue.dart';

/// Builds the gallery's scene graph, and owns everything it allocates.
///
/// Separated from the widget that displays it because construction is
/// asynchronous and the GPU resources it creates have to be released
/// deliberately — textures and images are not garbage collected. Anything
/// this builder makes, it also disposes.
class GalleryScene {
  GalleryScene._(this.scene, this.cue, this._artwork, this._textures);

  final Scene scene;

  /// The entrance cue, exposed so the view can advance its beckon. Nothing
  /// else in the scene animates on its own clock.
  final ThresholdCue cue;

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
    TextStyle? cueStyle,
    void Function(double)? onProgress,
  }) async {
    // Geometry and materials touch the shader bundle, so nothing can be
    // constructed before the engine's static resources exist.
    await Scene.initializeStaticResources();
    onProgress?.call(_shaderShare);

    final scene = Scene();
    final artwork = <ui.Image>[];
    final textures = <Texture2D>[];

    await _populate(scene, artwork, textures, artworkSize, onProgress);
    _light(scene);

    final cue = ThresholdCue.build(style: cueStyle ?? _defaultCueStyle);
    scene.add(cue.node);

    onProgress?.call(1);

    return _ready = GalleryScene._(scene, cue, artwork, textures);
  }

  /// Share of the build spent bringing the shader bundle up, before any
  /// artwork exists to report against.
  static const double _shaderShare = 0.15;

  /// Used when the caller has no theme to hand — the loading screen builds
  /// the gallery before any widget with a context is mounted over it.
  static const TextStyle _defaultCueStyle = TextStyle(
    color: ui.Color(0xFFFFE0A8),
    fontSize: 64,
    fontWeight: FontWeight.w300,
    letterSpacing: 14,
  );

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
    artwork..add(normal)..add(rough);

    final normalTexture = await Texture2D.fromImage(normal);
    final roughTexture = await Texture2D.fromImage(rough);
    textures..add(normalTexture)..add(roughTexture);

    final pieces = GalleryLayout.build();
    final frameCount = pieces.where((p) => p.kind == SurfaceKind.frame).length;
    var framesDone = 0;

    for (final piece in pieces) {
      // Design space in, engine space out — see [SceneAxes]. Position and
      // rotation have to cross together; flipping one without the other
      // leaves every frame facing into its own wall.
      final transform = Matrix4.translation(SceneAxes.position(piece.position));
      if (piece.rotationY != 0) {
        transform.rotateY(SceneAxes.rotationY(piece.rotationY));
      }

      final Material material;
      if (piece.kind == SurfaceKind.frame) {
        final image = await ProjectArtwork.render(
          piece.project!,
          size: artworkSize,
        );
        artwork.add(image);

        final texture = await Texture2D.fromImage(image);
        textures.add(texture);

        material = PhysicallyBasedMaterial(baseColorTexture: texture)
          ..roughnessFactor = 0.6
          ..metallicFactor = 0;

        // Reported per frame rather than per piece: the shell is effectively
        // instant, and a bar that jumps on the cheap work then stalls on the
        // expensive work is worse than no bar at all.
        framesDone++;
        onProgress?.call(
          _shaderShare + (1 - _shaderShare) * (framesDone / frameCount),
        );
      } else {
        material = _surfaceOf(piece.kind, normalTexture, roughTexture);
      }

      final geometry = switch (piece.kind) {
        SurfaceKind.floor || SurfaceKind.ceiling => PlaneGeometry(
          width: piece.extents.x,
          depth: piece.extents.z,
        ),
        _ => CuboidGeometry(piece.extents),
      };

      scene.add(Node(mesh: Mesh(geometry, material), localTransform: transform));
    }
  }

  /// Hangs the lights described by [GalleryLighting].
  ///
  /// A spot's aim is its node's business, not the light's: the direction is
  /// given in local space and rotated by the node's transform, so each light
  /// is placed by translation and aimed by the direction it carries.
  static void _light(Scene scene) {
    for (final light in GalleryLighting.build()) {
      final colour = Vector3(
        light.colour.r,
        light.colour.g,
        light.colour.b,
      );

      final node = Node(localTransform: Matrix4.translation(
        SceneAxes.position(light.position),
      ));

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

  static PhysicallyBasedMaterial _surfaceOf(
    SurfaceKind kind,
    Texture2D normal,
    Texture2D rough,
  ) {
    final base = switch (kind) {
      SurfaceKind.floor => _material(const ui.Color(0xFF8A7A62), 0.85, 0.05),
      SurfaceKind.ceiling => _material(const ui.Color(0xFFD9C7B8), 0.5, 0),
      _ => _material(const ui.Color(0xFFD4A97E), 0.75, 0.08),
    };

    // The floor and ceiling are seen at a glancing angle and read fine flat;
    // the walls are what the picture lights rake across, so they are the
    // surfaces that need something to catch.
    if (kind == SurfaceKind.floor || kind == SurfaceKind.ceiling) return base;

    return base
      ..normalTexture = normal
      ..normalTextureTransform = _tiled
      ..metallicRoughnessTexture = rough
      ..metallicRoughnessTextureTransform = _tiled;
  }

  /// Detail maps are tiled, not stretched: one repeat of a 512px map across a
  /// thirty-metre wall is invisible.
  static TextureTransform get _tiled => TextureTransform(
    scale: Vector2.all(SurfaceTextures.tiling),
  );

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
