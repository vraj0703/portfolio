import 'dart:ui' as ui;

import 'package:flutter_scene/scene.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';
import 'package:portfolio/domain/radio/radio_player.dart';
import 'package:portfolio/domain/style/text_styles.dart';
import 'package:portfolio/presentation/gallery/radio_face.dart';
import 'package:portfolio/presentation/gallery/scene_axes.dart';
import 'package:vector_math/vector_math.dart';

/// The radio hanging on the corridor's right wall.
///
/// One node with one material, whose texture is replaced whenever the radio
/// changes. That is the whole of it: the room's signage is baked once because
/// a wall does not change its mind, and this is baked again on every press
/// because a device with a display on it does.
///
/// The rasterised image behind each face is released as the next goes in.
/// The uploaded texture is not, because `Texture2D` offers no way to — it is
/// left to the collector, which is worth knowing rather than assuming: a
/// visitor who plays with the dial makes a handful of them, and if that ever
/// shows as GPU memory climbing, this is where it comes from.
/// Every radio in the building, lettered together.
///
/// There are two — one by the corridor's entrance and one in the skills hall
/// — and they are the same radio: one player, one state, two faces. A visitor
/// who starts it downstairs and walks up should not find the hall's set
/// reading OFF.
class WallRadios {
  WallRadios._(this._radios);

  final List<WallRadio> _radios;

  static Future<WallRadios> build({
    required RadioState state,
    required AppTypography type,
  }) async {
    final panels = GalleryLayout.build()
        .where((piece) => piece.kind == SurfaceKind.radio)
        .toList();

    return WallRadios._(<WallRadio>[
      for (final panel in panels)
        await WallRadio.build(panel: panel, state: state, type: type),
    ]);
  }

  Iterable<Node> get nodes => _radios.map((radio) => radio.node);

  /// Re-letters every face.
  /// What the wall is currently being lettered with, if anything.
  ///
  /// Lettering a face is asynchronous — rasterise, upload, swap — and a
  /// `StreamSubscription` does not wait for an async listener before
  /// delivering the next event. Two changes close together would therefore
  /// letter concurrently, and whichever finished last would win regardless
  /// of which happened last. Chaining makes the order of arrival the order
  /// of appearance.
  Future<void> _lettering = Future<void>.value();

  Future<void> show({
    required RadioState state,
    required AppTypography type,
  }) {
    _lettering = _lettering.then((_) => _letterAll(state, type));
    return _lettering;
  }

  Future<void> _letterAll(RadioState state, AppTypography type) async {
    for (final radio in _radios) {
      await radio.show(state: state, type: type);
    }
  }

  void dispose() {
    for (final radio in _radios) {
      radio.dispose();
    }
  }
}

class WallRadio {
  WallRadio._(this.node, this._material, this._panel);

  final Node node;
  final UnlitMaterial _material;

  /// Where it hangs, kept for nothing but its extents — the face is drawn on
  /// a cuboid cut to the placement, so the two cannot disagree about size.
  final Placement _panel;

  /// The image currently on the wall, held so it can be released.
  ///
  /// Only the image. The texture it was uploaded into is handed to the
  /// material and forgotten — `Texture2D` offers no way to free one, so
  /// holding a reference would only be a field nothing could act on.
  ui.Image? _shown;

  static Future<WallRadio> build({
    required Placement panel,
    required RadioState state,
    required AppTypography type,
  }) async {
    final material = UnlitMaterial()..alphaMode = AlphaMode.blend;

    final transform = Matrix4.translation(SceneAxes.position(panel.position))
      ..rotateY(SceneAxes.rotationY(panel.rotationY));

    final radio = WallRadio._(
      Node(
        mesh: Mesh(CuboidGeometry(panel.extents), material),
        localTransform: transform,
      ),
      material,
      panel,
    );

    await radio.show(state: state, type: type);
    return radio;
  }

  /// Re-letters the face for [state].
  ///
  /// Cheap enough to call on every change: the image is under a megabyte and
  /// the whole of it — rasterise, upload, swap, release — happens between two
  /// presses of a button.
  Future<void> show({
    required RadioState state,
    required AppTypography type,
  }) async {
    final image = await RadioFace.render(state: state, type: type);
    final texture = await Texture2D.fromImage(image);

    final previous = _shown;

    _shown = image;
    _material.baseColorTexture = texture;

    // Released *after* the swap, never before: freeing what the material is
    // still pointing at leaves a frame drawing from nothing.
    previous?.dispose();
  }

  /// How wide the face is, for anything that needs to reason about it.
  Vector3 get extents => _panel.extents;

  void dispose() {
    _shown?.dispose();
    _shown = null;
  }
}
