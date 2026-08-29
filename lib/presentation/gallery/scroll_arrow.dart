import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_scene/scene.dart';
import 'package:portfolio/domain/gallery/gallery_dimensions.dart';
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
  ScrollArrow._(this.node);

  final Node node;

  /// Where it lies, in design coordinates: just inside the entrance, on the
  /// centre line, ahead of where the visitor starts.
  static const double heightAboveFloor = 0.06;
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

      _light(model);

      // `add`, not `children.add`. The list is public and appending to it
      // looks like it works — the model appears, in the scene, at the right
      // place in the tree. What it does not do is set the child's parent or
      // mark its world transform dirty, so the child never composes with this
      // node's transform: every rotation and scale set here is silently
      // ignored and the model renders exactly as authored.
      final node = Node()..add(model);
      final arrow = ScrollArrow._(node);
      arrow.update(0, 0);
      return arrow;
    } catch (_) {
      return null;
    }
  }

  /// Colour the cue glows, matching the room's other lettering.
  static final Vector4 glow = Vector4(1, 0.78, 0.42, 1);

  /// Replaces the model's own material with one that lights itself.
  ///
  /// The corridor is deliberately dim, and the picture lights are aimed at
  /// the work rather than at the floor — a cue shaded by the room would sit
  /// in the darkest part of it. This is an instruction, not an exhibit: it
  /// has to be the thing the visitor notices first, so it carries its own
  /// light the way the wall signs do.
  ///
  /// The imported material is discarded rather than tinted. It arrived
  /// authored for whatever lighting the model was made under, and matching
  /// that to this room is more work than replacing it.
  static void _light(Node model) {
    for (final primitive in model.mesh?.primitives ?? const <MeshPrimitive>[]) {
      primitive.material = UnlitMaterial()..baseColorFactor = glow;
    }
    for (final child in model.children) {
      _light(child);
    }
  }

  /// Advances the bob and decides whether the cue still has anything to say.
  void update(double elapsed, double progress) {
    node.visible = progress < fadesBy;
    if (!node.visible) return;

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
          ..rotateY(SceneAxes.rotationY(facing))
          ..scaleByDouble(scale, scale, scale, 1);
  }
}
