import 'package:flutter/foundation.dart';
import 'package:flutter_scene/scene.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';
import 'package:portfolio/domain/radio/radio_player.dart';
import 'package:portfolio/domain/style/text_styles.dart';
import 'package:portfolio/presentation/gallery/radio_face.dart';
import 'package:portfolio/presentation/gallery/scene_axes.dart';
import 'package:vector_math/vector_math.dart';

/// Every radio in the building, lettered together.
///
/// There are two — one by the corridor's entrance and one in the skills hall
/// — and they are the same radio: one player, one state, two faces. A visitor
/// who starts it downstairs and walks up should not find the hall's set
/// reading OFF.
///
/// **Faces are baked once and kept.** Lettering one is not cheap, and the
/// measurement is worth writing down because it was assumed to be: rendering
/// the engraving takes about 450ms and reading it back for upload another
/// 490ms, on the main isolate, for a single face. Re-rendering per radio on
/// every change therefore cost close to two seconds of frozen scroll — and
/// that is exactly what it did. It showed up as a hitch in the corridor that
/// survived two wrong explanations, because it had nothing to do with where
/// the visitor was: it happened when the radio changed its mind, whichever
/// way they happened to be scrolling at the time.
///
/// So a face is a function of the state alone, both radios wear the same one,
/// and one that has been drawn before is never drawn again.
class WallRadios {
  WallRadios._(this._radios, this._faces);

  final List<WallRadio> _radios;

  /// Every face drawn so far, by the state it shows.
  ///
  /// Small and bounded: a status and a station, so four stations across three
  /// statuses is the whole space. Never evicted — a texture already on the
  /// GPU costs nothing to keep and most of a second to rebuild.
  final Map<String, Texture2D> _faces;

  /// What makes two states the same face.
  ///
  /// The status and the station, because those are the only two things the
  /// face draws. Volume and mute are deliberately absent: they change the
  /// radio without changing its picture, so keying on them would rebake a
  /// face already on the wall — and the whole point of the cache is that the
  /// expensive thing happens once.
  @visibleForTesting
  static String faceKey(RadioState state) =>
      '${state.status.name}:${state.station}';

  static Future<WallRadios> build({
    required RadioState state,
    required AppTypography type,
  }) async {
    final panels = GalleryLayout.build()
        .where((piece) => piece.kind == SurfaceKind.radio)
        .toList();

    final faces = <String, Texture2D>{};

    // Every face the radio can show *without the visitor touching the dial*,
    // drawn here where the loading screen is already asking them to wait.
    //
    // The scene puts the radio on air a little after they arrive, and it goes
    // off again if the stream will not open — so off, tuning and on-air all
    // happen in the first few seconds in the corridor, unprompted. Baked
    // lazily those were three stalls during the one stretch of the visit that
    // is nothing but scrolling. Stepping the dial still costs a bake, but
    // that is a press the visitor made and waited on, once per station ever.
    for (final status in RadioStatus.values) {
      final at = state.copyWith(status: status);
      faces[faceKey(at)] = await _bake(at, type);
    }

    final radios = <WallRadio>[
      for (final panel in panels)
        WallRadio._build(panel: panel, face: faces[faceKey(state)]!),
    ];

    return WallRadios._(radios, faces);
  }

  /// Draws one face and uploads it.
  ///
  /// The image is released as soon as it is uploaded: `Texture2D.fromImage`
  /// reads its bytes and keeps its own copy, so holding the original past
  /// this point is a megabyte of nothing.
  static Future<Texture2D> _bake(RadioState state, AppTypography type) async {
    final image = await RadioFace.render(state: state, type: type);
    final texture = await Texture2D.fromImage(image);
    image.dispose();
    return texture;
  }

  Iterable<Node> get nodes => _radios.map((radio) => radio.node);

  /// How many faces have been drawn, for anything counting the work.
  int get bakedFaces => _faces.length;

  /// The work in flight, so two changes cannot letter at once.
  ///
  /// A `StreamSubscription` does not wait for an async listener before
  /// delivering the next event, so two changes close together would resolve
  /// concurrently and whichever *finished* last would win — regardless of
  /// which happened last. Chaining makes the order of arrival the order of
  /// appearance.
  Future<void> _lettering = Future<void>.value();

  Future<void> show({
    required RadioState state,
    required AppTypography type,
  }) {
    _lettering = _lettering.then((_) => _wearFace(state, type));
    return _lettering;
  }

  Future<void> _wearFace(RadioState state, AppTypography type) async {
    final key = faceKey(state);
    final face = _faces[key] ??= await _bake(state, type);

    // One face, worn by both. They show the same radio, so drawing it twice
    // was the same picture at twice the price.
    for (final radio in _radios) {
      radio.wear(face);
    }
  }

  void dispose() {
    // Nothing to release. The images were freed at upload, and `Texture2D`
    // offers no way to free a texture — they go with the GPU context.
  }
}

class WallRadio {
  WallRadio._(this.node, this._material, this._panel);

  final Node node;
  final UnlitMaterial _material;

  /// Where it hangs, kept for nothing but its extents — the face is drawn on
  /// a cuboid cut to the placement, so the two cannot disagree about size.
  final Placement _panel;

  static WallRadio _build({
    required Placement panel,
    required Texture2D face,
  }) {
    final material = UnlitMaterial()..alphaMode = AlphaMode.blend;

    final transform = Matrix4.translation(SceneAxes.position(panel.position))
      ..rotateY(SceneAxes.rotationY(panel.rotationY));

    return WallRadio._(
      Node(
        mesh: Mesh(CuboidGeometry(panel.extents), material),
        localTransform: transform,
      ),
      material,
      panel,
    )..wear(face);
  }

  /// Puts [face] on the wall.
  ///
  /// A pointer swap and nothing else — the drawing happened elsewhere, once.
  void wear(Texture2D face) => _material.baseColorTexture = face;

  /// How wide the face is, for anything that needs to reason about it.
  Vector3 get extents => _panel.extents;
}
