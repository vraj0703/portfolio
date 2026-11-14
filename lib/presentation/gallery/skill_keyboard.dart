import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';
import 'package:portfolio/domain/gallery/keyboard_layout.dart';
import 'package:portfolio/domain/gallery/skill_data.dart';
import 'package:portfolio/presentation/gallery/rounded_box.dart';
import 'package:portfolio/presentation/gallery/scene_axes.dart';
import 'package:portfolio/presentation/gallery/texture_sets.dart';
import 'package:vector_math/vector_math.dart';

/// The skills keyboard, floating in its hall.
///
/// Built from the arrangement in [KeyboardLayout] rather than deciding
/// anything itself, for the same reason the corridor is: where the caps go is
/// checkable without a renderer, and a row centred on the wrong width is
/// invisible from inside a running scene.
class SkillKeyboard {
  SkillKeyboard._(this.node, this._caps);

  final Node node;
  final Map<String, _Cap> _caps;

  /// The turn that presents the board to whoever walks in.
  ///
  /// The visitor arrives along `+x` and looks back along it, so the board's
  /// rows have to run across `z` to face them. Without this they arrive at
  /// the board edge-on, reading a row of key *sides*.
  ///
  /// It is also what makes the caps pickable: at rest the face of every cap
  /// spans `z` and `y`, which is the one arrangement the gallery's picker
  /// already understands.
  static const double restRotation = math.pi / 2;

  /// Case colour — dark, so the keycaps are the brightest thing on it.
  static final Vector4 caseColour = Vector4(0.07, 0.065, 0.06, 1);

  /// Cap body, when the photographed metal cannot be read.
  static final Vector4 capColour = Vector4(0.62, 0.63, 0.66, 1);

  /// How rough a bare cap is, in that same fallback.
  ///
  /// No clearcoat, and no transmission before it. Both are gone for the same
  /// reason rather than two: each asks the renderer for a shader the rest of
  /// the room does not use, and the board is the only thing in the gallery
  /// that appears all at once, in view, part-way through a scroll. Whatever
  /// it costs to draw for the first time is paid on that single frame, and
  /// the visitor reads it as the page having died.
  ///
  /// Every material on the board is now the same plain physically-based one
  /// the corridor's walls and floor use. By the time the board rises, that
  /// shader has been compiled and running for the whole walk.
  static const double capRoughness = 0.34;

  /// How much of a cap's own colour reaches its face.
  ///
  /// The keycaps carry the only colour in this room, and the hall's fills are
  /// warm and low. Without a little self-illumination every accent turns to
  /// the same amber as everything else and the board reads as one object
  /// rather than as a set of labelled keys.
  static const double legendGlow = 0.55;

  /// How much brighter the chosen cap burns.
  static const double selectedGlow = 1.6;

  /// How far a chosen cap rises out of the board.
  static const double pressLift = 0.12;

  static SkillKeyboard build({
    SurfaceMaps? base,
    List<SurfaceMaps?> rows = const <SurfaceMaps?>[],
  }) {
    final root = Node();
    final caps = <String, _Cap>{};
    final scale = KeyboardLayout.scale;

    root.add(
      Node(
        mesh: Mesh(
          RoundedBox.build(
            Vector3(
              KeyboardLayout.boardWidth * scale,
              KeyboardLayout.boardHeight * scale,
              KeyboardLayout.boardDepth * scale,
            ),
            // A quarter of its own thickness. At nearly half — which is what
            // this was — a slab this thin rounds almost to a capsule and the
            // straight section vanishes, so the case reads as a bar of soap
            // rather than as something with edges that were machined.
            radius: KeyboardLayout.boardHeight * scale * 0.25,
          ),
          // Photographed timber where it can be read, and the flat dark case
          // where it cannot. The case is the one part of the board with any
          // area to it, so it is the one part where a surface reads at all —
          // the caps are too small to carry anything but their colour.
          base?.materialFor(
                KeyboardLayout.boardWidth * scale,
                KeyboardLayout.boardDepth * scale,
              ) ??
              (PhysicallyBasedMaterial()
                ..baseColorFactor = caseColour
                ..metallicFactor = 0.7
                ..roughnessFactor = 0.35),
        ),
      ),
    );

    // One geometry for all 26 caps. They are the same size, so building a
    // rounded box each would be 26 identical vertex buffers on the GPU.
    final capGeometry = RoundedBox.build(
      KeyboardLayout.keys().first.extents * scale,
    );

    final capSize = KeyboardLayout.capSize * scale;

    for (final key in KeyboardLayout.keys()) {
      // One metal per row, cycled. Four rows and three sets, so the last row
      // shares the first's alloy — which is fine, because the rows it needs
      // to be told apart from are its neighbours.
      final metal = rows.isEmpty ? null : rows[key.row % rows.length];

      final material =
          metal?.materialFor(capSize, capSize) ??
          (PhysicallyBasedMaterial()
            ..baseColorFactor = capColour
            ..metallicFactor = 1
            ..roughnessFactor = capRoughness);

      final node = Node(mesh: Mesh(capGeometry, material));
      root.add(node);

      final cap = _Cap(key, node, material);
      caps[key.skill.id] = cap;
      cap.place(lifted: false);
    }

    final keyboard = SkillKeyboard._(root, caps);
    keyboard.reveal(1);
    return keyboard;
  }

  /// Where each cap sits in the room *right now*, for picking.
  ///
  /// Recomputed from the board's current turn rather than cached at rest.
  /// The visitor can turn the board, and a cached set of positions would go
  /// on describing where the keys used to be — clicks would land on whatever
  /// key happened to have been there before, which is worse than not working
  /// at all.
  ///
  /// The instances are kept so a hit can be traced back to its skill by
  /// identity. For 26 caps a few centimetres apart, matching on position
  /// would be a floating-point tolerance argument nobody should have to have.
  List<Placement> keycaps() {
    final scale = KeyboardLayout.scale;
    final anchor = KeyboardLayout.anchor;
    final size = KeyboardLayout.capSize * scale;

    // The board's own turn, in design space. The renderer applies the
    // mirrored form of the same thing, so positions computed here and
    // converted at the boundary agree with what is on screen.
    final turn = Matrix4.rotationY(restRotation)..rotateX(_tilt);

    _lastPlacements = _caps.values.map((cap) {
      final local = Vector3(
        cap.key.position.x * scale,
        cap.lift(false),
        cap.key.position.z * scale,
      );

      return Placement(
        kind: SurfaceKind.keycap,
        position: anchor + turn.transformed3(local),
        extents: Vector3(size, size, size),
      );
    }).toList();

    return _lastPlacements;
  }

  List<Placement> _lastPlacements = const <Placement>[];

  /// The skill whose cap this is, or null if it is not one of ours.
  Skill? skillAt(Placement placement) {
    final index = _lastPlacements.indexWhere((p) => identical(p, placement));
    if (index < 0) return null;
    return _caps.values.elementAt(index).key.skill;
  }

  /// Raises and brightens one cap, and returns the rest.
  void select(Skill? skill) {
    for (final cap in _caps.values) {
      cap.place(lifted: cap.key.skill.id == skill?.id);
    }
  }

  /// Where the board starts before it has risen, below the floor.
  static const double hiddenDrop = 2.2;

  /// The tilt it rises out of, easing back to [restTilt].
  ///
  /// It comes up steeper than it settles, so the caps are turned toward the
  /// visitor as it arrives and then relax — the same gesture the original
  /// used to make the board look like it was presenting itself.
  static const double revealTilt = 0.6;
  static const double restTilt = 0.35;

  double _tilt = restTilt;
  double _reveal = 1;
  double _bob = 0;

  /// How far the board has risen, `0`..`1`, where it is in its breath, and
  /// how long the frame took.
  ///
  /// The rise is read off the scroll, because it has to run backwards when
  /// the visitor does. Its *heading* is not: that wanders while it comes up
  /// and is pulled home on a clock of its own, which is the difference
  /// between an object floating in a room and a panel on a rail. The visitor
  /// turns the camera around it rather than turning it — see [KeyboardOrbit].
  /// How far the board is turned from its resting heading.
  double _heading = 0;

  /// Turns it while it is still coming up, and pulls it home once it is not.
  ///
  /// The rule lives in [KeyboardLayout.headingAfter]; this only remembers
  /// where the board got to.
  void _drift(double elapsed, double dt) {
    _heading = KeyboardLayout.headingAfter(
      heading: _heading,
      reveal: _reveal,
      elapsed: elapsed,
      dt: dt,
    );
  }

  void reveal(double amount, {double elapsed = 0, double dt = 0}) {
    _reveal = amount.clamp(0.0, 1.0);

    // Breathing the whole way up, scaled by how far it has come rather than
    // switched on at the top. It was held at zero until the rise finished,
    // on the reasoning that a wobble during the rise would read as two
    // movements — but the thing that actually read as wrong was a board with
    // no life in it at all until it stopped moving.
    _bob =
        math.sin(elapsed * KeyboardLayout.bobRate) *
        KeyboardLayout.bobHeight *
        _reveal;

    _drift(elapsed, dt);

    // Overshoots a little and settles back, so it arrives with weight rather
    // than sliding to a halt. The original eased its boot the same way.
    const overshoot = 1.70158;
    final t = _reveal - 1;
    final eased = t * t * ((overshoot + 1) * t + overshoot) + 1;

    _tilt = revealTilt + (restTilt - revealTilt) * eased;
    final anchor = KeyboardLayout.anchor;

    node
      ..visible = _reveal > 0
      ..localTransform =
          (Matrix4.translation(
            SceneAxes.position(
              Vector3(
                anchor.x,
                anchor.y - hiddenDrop * (1 - eased) + _bob,
                anchor.z,
              ),
            ),
          )
            ..rotateY(SceneAxes.rotationY(restRotation + _heading))
            // Tips toward the visitor, so they see the tops of the caps
            // rather than looking along them edge-on. Unaffected by the axis
            // mirror: reflecting x leaves a turn about x alone.
            ..rotateX(_tilt));
  }
}

class _Cap {
  _Cap(this.key, this.node, this.material);

  final KeyPlacement key;
  final Node node;
  final PhysicallyBasedMaterial material;

  double lift(bool lifted) =>
      (KeyboardLayout.boardHeight + key.extents.y) / 2 * KeyboardLayout.scale +
      (lifted ? SkillKeyboard.pressLift : 0);

  void place({required bool lifted}) {
    final scale = KeyboardLayout.scale;
    final colour = key.skill.color;
    final glow = lifted ? SkillKeyboard.selectedGlow : SkillKeyboard.legendGlow;

    // Lit from inside rather than tinted on the surface, so a pressed key
    // reads as the glass itself glowing rather than as a swatch changing
    // colour.
    material.emissiveFactor = Vector4(
      colour.r * glow,
      colour.g * glow,
      colour.b * glow,
      1,
    );

    node.localTransform = Matrix4.translation(
      SceneAxes.position(
        Vector3(key.position.x * scale, lift(lifted), key.position.z * scale),
      ),
    );
  }
}
