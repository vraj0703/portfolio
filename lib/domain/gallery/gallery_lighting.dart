import 'dart:ui';

import 'package:vector_math/vector_math.dart';

import 'gallery_dimensions.dart';
import 'project_data.dart';

enum LightKind {
  /// A cone aimed at something — how the work is actually lit.
  spot,

  /// An omnidirectional fill that keeps the room from going black between
  /// the pools of light.
  point,
}

/// One light in the gallery.
class LightPlacement {
  const LightPlacement({
    required this.kind,
    required this.position,
    required this.colour,
    required this.intensity,
    this.direction,
    this.range = 0,
    this.innerCone = 0,
    this.outerCone = 0.45,
  });

  final LightKind kind;
  final Vector3 position;

  /// Aim, in the light's own space. Only meaningful for [LightKind.spot].
  final Vector3? direction;

  final Color colour;
  final double intensity;

  /// Distance at which the light stops reaching. `0` means unbounded.
  final double range;

  /// Cone half-angles, in radians.
  final double innerCone;
  final double outerCone;
}

/// How the gallery is lit.
///
/// A museum corridor is not evenly lit — it is a dim room with the work
/// picked out of it. Each piece gets its own cone from above, and a sparse
/// warm fill keeps the space between them from reading as black rather than
/// as shadow.
///
/// Pure data, like [GalleryLayout], because the interesting failures here are
/// positional: a light behind the wall it is meant to illuminate, or aimed
/// past the piece it belongs to, produces a dark frame and nothing else.
abstract final class GalleryLighting {
  /// Warm white, matching the original's picture lights.
  static const Color frameLight = Color(0xFFFFE0B0);

  /// Slightly cooler fill so the pools of light read as warmer by contrast.
  static const Color fill = Color(0xFFFFF0D8);

  /// Flat warm light reaching every surface, whichever way it faces.
  ///
  /// The original carried both an ambient and a hemisphere light, and between
  /// them they did most of the work of making the room legible — the spots
  /// and fills only picked the work out of it. Without an equivalent, every
  /// surface not directly under a light falls to black, which reads as a hole
  /// in the room rather than as shadow.
  ///
  /// Expressed as radiance rather than as a light: the renderer's ambient
  /// term is its image-based-lighting environment, so a constant colour there
  /// is what a flat ambient light amounts to.
  static final Vector3 ambient = Vector3(0.55, 0.53, 0.48);

  /// How far above a frame its light hangs.
  static const double lightHeightAbove = 2.2;

  /// How far out from the wall the light hangs, so it rakes across the work
  /// rather than flattening it head-on.
  static const double lightStandoff = 0.9;

  /// What a piece still in progress gets, as a fraction of a full light.
  ///
  /// The room saying it before the card does. A gallery hanging work that is
  /// not ready does not pretend otherwise — and it does not need a sign,
  /// because the lighting already tells you: the finished pieces are lit to
  /// be looked at, and the rest are visible rather than presented.
  ///
  /// Dim, not dark. Unlit reads as broken; this reads as deliberate.
  static const double unfinishedLight = 0.35;

  /// Fill lights sit along the centre line at this spacing.
  ///
  /// Closer together than the original's, because each one has to reach the
  /// floor as well as the air: a museum corridor is meant to be dim, but a
  /// *floor* that goes black stops reading as a floor and starts reading as
  /// a hole the visitor is walking over.
  static const double fillSpacing = 7;

  static List<LightPlacement> build() => <LightPlacement>[
    ..._frameLights(GalleryProjects.left, onLeft: true),
    ..._frameLights(GalleryProjects.right, onLeft: false),
    ..._fill(),
    ..._testimonialLights(),
    _backWall(),
  ];

  /// One cone per frame on the far wall.
  ///
  /// The wall wash alone reaches the plaster but not the work on it, and the
  /// lesson from every other surface in this room is that a thing nobody
  /// lights is a thing nobody sees. Hung in front of the wall and aimed back
  /// at it, like the corridor's picture lights.
  static Iterable<LightPlacement> _testimonialLights() sync* {
    for (var i = 0; i < GalleryDimensions.testimonialCount; i++) {
      yield LightPlacement(
        kind: LightKind.spot,
        position: Vector3(
          GalleryDimensions.testStartX + i * GalleryDimensions.testSpacing,
          GalleryDimensions.frameY + lightHeightAbove,
          GalleryDimensions.backWallZ + lightStandoff + 0.6,
        ),
        direction: Vector3(0, -1, 1)..normalize(),
        colour: frameLight,
        intensity: 10,
        range: 8,
        innerCone: 0.2,
        outerCone: 0.5,
      );
    }
  }

  /// One cone per piece, hung above and slightly out from the wall, aimed
  /// back at the work.
  static Iterable<LightPlacement> _frameLights(
    List<Project> projects, {
    required bool onLeft,
  }) sync* {
    for (var i = 0; i < projects.length; i++) {
      final z = -(i + 1) * GalleryDimensions.spacing;
      final wallX = onLeft ? -GalleryDimensions.wallX : GalleryDimensions.wallX;
      final inward = onLeft ? 1.0 : -1.0;

      yield LightPlacement(
        kind: LightKind.spot,
        position: Vector3(
          wallX + inward * lightStandoff,
          GalleryDimensions.frameY + lightHeightAbove,
          z,
        ),
        // Down and back toward the wall: the aim is what makes it a picture
        // light rather than a downlight that misses the work entirely.
        direction: Vector3(-inward, -1, 0)..normalize(),
        colour: frameLight,
        intensity: 12 * (projects[i].isLive ? 1 : unfinishedLight),
        range: 8,
        innerCone: 0.2,
        outerCone: 0.5,
      );
    }
  }

  /// Sparse warm fill down the middle of the corridor.
  ///
  /// Starts within a stride of the entrance rather than a full spacing in.
  /// Beginning at the first interval left the opening stretch — the part the
  /// visitor spends longest looking at, and where the first pieces hang —
  /// lit only by picture spots aimed at the walls, so the floor beneath them
  /// read as unlit rather than as shadow.
  static Iterable<LightPlacement> _fill() sync* {
    for (
      var z = -fillSpacing / 2.5;
      z > GalleryDimensions.backWallZ;
      z -= fillSpacing
    ) {
      yield LightPlacement(
        kind: LightKind.point,
        position: Vector3(0, GalleryDimensions.ceilY - 0.6, z),
        colour: fill,
        intensity: 9,
        range: 18,
      );
    }
  }

  /// Washes the far wall, so the end of the corridor reads as a destination
  /// rather than as the point at which the light runs out.
  static LightPlacement _backWall() => LightPlacement(
    kind: LightKind.spot,
    position: Vector3(
      0,
      GalleryDimensions.ceilY - 0.4,
      GalleryDimensions.backWallZ + 3,
    ),
    direction: Vector3(0, -1, -1)..normalize(),
    colour: frameLight,
    intensity: 18,
    range: 14,
    innerCone: 0.3,
    outerCone: 0.7,
  );
}
