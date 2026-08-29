import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_scene/scene.dart';
import 'package:portfolio/domain/gallery/gallery_dimensions.dart';
import 'package:portfolio/presentation/gallery/icon_metal.dart';
import 'package:portfolio/presentation/gallery/scene_axes.dart';
import 'package:vector_math/vector_math.dart';

/// The arrow at the corridor entrance that says the room is walkable.
///
/// A model rather than lettering. The corridor's one instruction used to be
/// the word SCROLL, which had to be read; an arrow lying on the floor pointing
/// down the corridor is understood without reading, and in a room this is the
/// more honest way to say it.
///
/// It leaves as soon as the visitor starts moving. A cue that follows them
/// down the corridor repeating itself has stopped being a cue.
class ScrollArrow {
  ScrollArrow._(this.node, this._lamp);

  final Node node;
  final PointLight _lamp;

  /// Where it hangs, in design coordinates: just inside the entrance, on the
  /// centre line, ahead of where the visitor starts.
  ///
  /// It floats rather than lies. The height has to clear [bobHeight] plus the
  /// model's own half thickness, or the bottom of every bob dips through the
  /// floor and the arrow flickers as it is clipped — which is what it did at
  /// six centimetres against a nine-centimetre bob. Well clear, not barely:
  /// a marking that grazes the floor reads as a fault rather than as a hover.
  static const double heightAboveFloor = 0.55;
  static const double distanceIn = -2.4;

  /// Turn about the vertical, so the arrow points *down* the corridor.
  ///
  /// A quarter turn, and no tilt with it. The mesh is authored face-on in its
  /// own XY plane, but the export wraps it in nodes that already apply the
  /// Z-up to Y-up conversion: composing them, the mesh's `+X` arrives as
  /// world `+X`, its `+Y` as `+Z`, and its `+Z` as `+Y`. So the arrow is
  /// delivered *already lying flat* — pointing straight across the corridor,
  /// which is what made it read as aimed at a wall. All it needs is turning.
  ///
  /// Worth knowing for the next model: what a glTF's accessor bounds describe
  /// is mesh space, not the space the node arrives in. Reading the bounds and
  /// assuming they are world axes is how a model ends up rotated twice.
  static const double facing = -math.pi / 2;

  /// The model is three units long as authored; the corridor is eight across.
  ///
  /// At half size it filled a third of the view — a marking, not a monument.
  /// This brings it to about a metre, the size of an arrow painted on a floor
  /// rather than one hung on a wall.
  static const double scale = 0.3;

  /// How far it rises and falls, in world units.
  static const double bobHeight = 0.09;

  /// Beats per second of the bob.
  static const double bobRate = 1.1;

  /// The scroll fraction by which it has fully gone.
  ///
  /// Short: the moment the corridor starts moving the arrow has done its job,
  /// and holding it any longer reads as it being part of the room.
  static const double fadesBy = 0.05;

  /// Loads the arrow, or returns null if it cannot be read.
  ///
  /// Null rather than a throw, like every other asset in this room: a missing
  /// cue is a room without a hint, while a missing cue that throws is no room
  /// at all. This one is especially worth guarding — a multi-file glTF is a
  /// *set* of files, and it fails at load time if any of them is absent.
  static Future<ScrollArrow?> load({
    String asset = 'assets/objects/direction_arrow.glb',
  }) async {
    try {
      final bytes = await rootBundle.load(asset);
      final directory = asset.substring(0, asset.lastIndexOf('/') + 1);

      final model = asset.endsWith('.glb')
          ? await Node.fromGlbBytes(bytes.buffer.asUint8List())
          : await Node.fromGltfBytes(
              bytes.buffer.asUint8List(),
              // A `.gltf` is JSON that names its geometry buffer and images as
              // sibling files; this is what fetches them. Without it — or
              // without the siblings actually being in the bundle — there is
              // nothing to draw.
              resolveUri: (uri) async {
                final data = await rootBundle.load('$directory$uri');
                return data.buffer.asUint8List();
              },
            );

      _surface(model);

      // Three nodes rather than one, so the scale lands only where it should.
      // The arrow is a third of its authored size; a lamp parented under that
      // scale would have its offset shrunk with it and end up buried in the
      // model. The scaling is pushed down to its own node instead, leaving
      // the lamp measured in world units.
      final scaled = Node(
        localTransform: Matrix4.identity()
          ..scaleByDouble(scale, scale, scale, 1),
      )..add(model);

      final lamp = PointLight(color: Vector3(1, 0.82, 0.55), range: 6);
      final lampNode = Node(
        localTransform: Matrix4.translation(Vector3(0, lampHeight, 0)),
      )..addComponent(PointLightComponent(lamp));

      // `add`, not `children.add`. The list is public and appending to it
      // looks like it works — the model lands in the scene, in the right
      // place in the tree, and renders. What it does not do is set the
      // child's parent or mark its world transform dirty, so the child never
      // composes with this node's transform: every rotation and scale set
      // here is silently discarded and the model appears exactly as authored.
      final node = Node()
        ..add(scaled)
        ..add(lampNode);

      final arrow = ScrollArrow._(node, lamp);
      arrow.update(0, 0);
      return arrow;
    } catch (_) {
      return null;
    }
  }

  /// Base colour of the metal — brass rather than steel, so it belongs to a
  /// room lit in warm tones.
  static final Vector4 brass = Vector4(0.94, 0.71, 0.36, 1);

  /// Kept just bright enough that the arrow is never wholly lost.
  ///
  /// Real metal in an unlit corner is black, and a cue that disappears when
  /// the visitor happens to stand in the wrong place has failed. This is a
  /// floor, not a fill: it should read as sheen, not as a lamp.
  static final Vector4 sheen = Vector4(0.16, 0.11, 0.05, 1);

  /// Height of the small lamp that travels with the arrow.
  static const double lampHeight = 1.4;

  /// How hard the lamp works while the cue is up.
  ///
  /// Enough to raise a highlight on the metal and no more. This is a spot of
  /// light on the floor at the entrance, not a second source competing with
  /// the picture lights down the corridor.
  static const double lampIntensity = 5;

  /// Gives the model a metal surface.
  ///
  /// Metal is *reflection*, which means it needs something to reflect. The
  /// corridor's fill lights start ten units in and its picture lights are
  /// aimed at the walls, so this spot of floor has almost nothing reaching
  /// it — hence the lamp above. Without it a fully metallic material is
  /// simply black, and the arrow was previously unlit for exactly that
  /// reason.
  ///
  /// The imported material is discarded rather than tinted: it arrived
  /// authored for whatever lighting the model was made under, and matching
  /// that to this room is more work than replacing it.
  static void _surface(Node model) {
    for (final primitive in model.mesh?.primitives ?? const <MeshPrimitive>[]) {
      primitive.material = IconMetal.of();
    }
    for (final child in model.children) {
      _surface(child);
    }
  }

  /// Advances the bob and decides whether the cue still has anything to say.
  void update(double elapsed, double progress) {
    final showing = progress < fadesBy;
    node.visible = showing;

    // The lamp is doused by hand, because hiding a node does not hide its
    // light: `PointLightComponent` registers with the scene on *mount* and
    // only unregisters when the node leaves it. Left alone, retiring the
    // arrow would leave an unexplained pool of light on the floor behind it.
    _lamp.intensity = showing ? lampIntensity : 0;

    if (!showing) return;

    final lift = math.sin(elapsed * bobRate * math.pi) * bobHeight;

    node.localTransform =
        Matrix4.translation(
            SceneAxes.position(
              Vector3(
                0,
                GalleryDimensions.floorY + heightAboveFloor + lift,
                distanceIn,
              ),
            ),
          )
          // Scale belongs to the model's own node now — see [load].
          ..rotateY(SceneAxes.rotationY(facing));
  }
}
