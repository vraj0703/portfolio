import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_scene/scene.dart';
import 'package:portfolio/domain/gallery/control_layout.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';
import 'package:portfolio/presentation/gallery/icon_metal.dart';
import 'package:portfolio/presentation/gallery/scene_axes.dart';
import 'package:vector_math/vector_math.dart';

/// The three controls, as objects in the room rather than chrome over it.
///
/// Models cost nothing per frame — they are meshes the renderer already walks
/// — which is what makes this workable where the earlier wall-mounted
/// controls were not. Those were `WidgetComponent` surfaces, and a widget
/// surface re-rasterises on its update policy whether or not it is visible,
/// so three of them ran a capture inside the render loop for the whole walk.
class ControlIcons {
  ControlIcons._(this.node, this._slots, this._lamp, this._lampNode);

  final Node node;
  final List<_Slot> _slots;
  final PointLight _lamp;

  /// The lamp's own node. Positioned in world space like the slots are — the
  /// root stays at identity, because every slot already carries a world
  /// transform and moving their parent would offset all three.
  final Node _lampNode;

  /// Height of the small lamp that travels with the row.
  static const double lampHeight = 0.9;

  /// How hard it works while the controls are up.
  ///
  /// The corridor's picture lights are aimed at the work, and the wall
  /// beneath a frame is the darkest part of the room — which is where these
  /// sit. Metal with nothing to reflect is black, so without this the icons
  /// are shapes with no shine and easy to miss entirely.
  static const double lampIntensity = 4;

  /// Where each control currently sits, for picking. Empty when hidden.
  List<ControlPlacement> get placements => _slots
      .where((s) => s.node.visible)
      .map((s) => s.placement)
      .nonNulls
      .toList();

  /// How much of the model's own height one world unit of [iconSize] buys.
  ///
  /// The arrow is 4.76 units tall as authored and the cross 6.44, so each
  /// needs its own divisor or one of them arrives twice the size of the
  /// other. Sizing by the model's own extent rather than a shared guess is
  /// what keeps a row of icons looking like a set.
  static const double arrowAuthoredHeight = 4.76;
  static const double crossAuthoredHeight = 6.44;

  /// Turn that stands the cross up into the wall's plane.
  ///
  /// It is authored lying flat in its own XZ plane — thin through Y — so a
  /// quarter turn about Z brings its face round to meet the corridor. The
  /// arrow needs no such turn: it is already upright in XY with its tip along
  /// X, which is the plane a wall occupies once it has been turned to face in.
  ///
  /// Signed by the wall. Standing it up one way puts its face toward the
  /// corridor; the other way puts it toward the plaster, where a single-sided
  /// surface is culled and shows nothing at all.
  static const double crossStandUp = math.pi / 2;

  /// Roll within its own plane, which is what turns a `+` into an `✕`.
  ///
  /// The model's arms run along its own X and Z, so standing it up lands them
  /// vertical and horizontal — a plus sign, which reads as "add" rather than
  /// "close". Applied *before* the stand-up so it turns the cross about its
  /// own face rather than swinging it out of the wall.
  static const double crossRoll = math.pi / 4;

  static Future<ControlIcons?> load() async {
    final root = Node();
    final slots = <_Slot>[];

    for (final action in ControlAction.values) {
      final isCross = action == ControlAction.exit;

      // Loaded once per slot rather than shared. A node has one parent and
      // one transform, so three controls in three places cannot be three
      // references to the same model.
      final model = await _model(
        isCross ? 'assets/objects/cross.glb' : 'assets/objects/arrow.glb',
      );
      if (model == null) return null;
      _surface(model);

      final size =
          ControlLayout.iconSize /
          (isCross ? crossAuthoredHeight : arrowAuthoredHeight);

      final scaled = Node(
        localTransform: Matrix4.identity()
          ..scaleByDouble(size, size, size, 1),
      )..add(model);

      final slot = Node()..add(scaled);
      root.add(slot);
      slots.add(_Slot(slot, action, isCross));
    }

    final lamp = PointLight(color: Vector3(1, 0.86, 0.62), range: 4);
    final lampNode = Node()..addComponent(PointLightComponent(lamp));
    root.add(lampNode);

    final icons = ControlIcons._(root, slots, lamp, lampNode);
    icons.hide();
    return icons;
  }

  /// Loads one model with its authored transform discarded.
  ///
  /// Both files carry a Blender object transform baked into the root node —
  /// the arrow a twenty-two degree rotation, the cross ninety-eight — which
  /// is bookkeeping from whatever scene they were exported out of, not
  /// something either shape means. Left in place the icons arrive visibly
  /// askew. Clearing it puts the mesh back on its own axes, which is the only
  /// frame of reference the geometry actually describes.
  static Future<Node?> _model(String asset) async {
    try {
      final bytes = await rootBundle.load(asset);
      final node = await Node.fromGlbBytes(bytes.buffer.asUint8List());
      _flatten(node);
      return node;
    } catch (_) {
      return null;
    }
  }

  static void _flatten(Node node) {
    node.localTransform = Matrix4.identity();
    for (final child in node.children) {
      _flatten(child);
    }
  }

  static void _surface(Node model) {
    for (final primitive in model.mesh?.primitives ?? const <MeshPrimitive>[]) {
      primitive.material = IconMetal.of();
    }
    for (final child in model.children) {
      _surface(child);
    }
  }

  /// Brings the row to [frame].
  void showFor(
    Placement frame, {
    required bool canGoBack,
    required bool canGoForward,
  }) {
    final row = ControlLayout.below(
      frame,
      canGoBack: canGoBack,
      canGoForward: canGoForward,
    );

    _lamp.intensity = lampIntensity;

    // The row's own light rides above its centre, which is the ✕ — the one
    // control that is always present. Given a world transform of its own
    // rather than an offset under the root, for the reason above.
    final centre = row.firstWhere((p) => p.action == ControlAction.exit);
    _lampNode.localTransform = Matrix4.translation(
      SceneAxes.position(
        Vector3(
          centre.position.x,
          centre.position.y + lampHeight,
          centre.position.z,
        ),
      ),
    );

    for (final slot in _slots) {
      final placement = row
          .where((p) => p.action == slot.action)
          .firstOrNull;

      slot.node.visible = placement != null;
      if (placement == null) continue;

      slot.placement = placement;

      // Design-left wall is engine-right, so the face that must meet the
      // corridor is on the opposite side for each of them.
      final standUp = frame.position.x.isNegative
          ? crossStandUp
          : -crossStandUp;

      slot.node.localTransform =
          Matrix4.translation(SceneAxes.position(placement.position))
            ..rotateY(SceneAxes.rotationY(ControlLayout.aimFor(slot.action)))
            ..rotateZ(slot.isCross ? standUp : 0)
            // Applied last in the cascade, so it is the *first* turn the mesh
            // sees: a roll about the cross's own normal, in its own plane.
            ..rotateY(slot.isCross ? crossRoll : 0);
    }
  }

  void hide() {
    for (final slot in _slots) {
      slot.node.visible = false;
    }
    // Doused by hand: `PointLightComponent` registers with the scene on mount
    // and only unregisters when its node leaves, so hiding the icons would
    // otherwise leave a pool of light on an empty stretch of wall.
    _lamp.intensity = 0;
  }
}

class _Slot {
  _Slot(this.node, this.action, this.isCross);

  final Node node;
  final ControlAction action;
  final bool isCross;

  /// Where this control last went. Null until it has been shown, which is
  /// also what keeps a hidden control out of the pick list.
  ControlPlacement? placement;
}
