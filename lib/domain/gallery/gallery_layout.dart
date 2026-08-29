import 'package:vector_math/vector_math.dart';

import 'gallery_dimensions.dart';
import 'project_data.dart';

/// What kind of surface a placement describes.
enum SurfaceKind {
  floor,
  ceiling,
  /// One of the two walls running the length of the corridor.
  sideWall,
  /// The far wall the testimonials hang on.
  backWall,

  /// The wall closing the testimonial wing behind the visitor.
  wingWall,
  /// A framed project.
  frame,

  /// The way out, painted on the left wall by the entrance.
  exitSign,
}

/// One piece of the gallery, positioned in world space.
class Placement {
  const Placement({
    required this.kind,
    required this.position,
    required this.extents,
    this.rotationY = 0,
    this.project,
  });

  final SurfaceKind kind;
  final Vector3 position;

  /// Full size on each axis. A plane ignores its `y`.
  final Vector3 extents;

  /// Rotation about the vertical axis, in radians.
  final double rotationY;

  /// The work shown here, for [SurfaceKind.frame].
  final Project? project;
}

/// The gallery's contents and where they sit.
///
/// Pure data, deliberately. Building the actual scene needs a GPU context,
/// which a test harness has no way to provide — so the decisions about what
/// the room contains and where things go live here, where they can be checked,
/// and the renderer becomes a loop that executes them.
///
/// That split is worth the indirection: a frame placed outside the corridor,
/// or facing the wall it hangs on, is invisible rather than wrong-looking, and
/// there is nothing in a running scene to say so.
abstract final class GalleryLayout {
  /// Quarter turn. Frames are rotated by this so they face *across* the
  /// corridor; a frame left unrotated is edge-on to the visitor.
  static const double quarterTurn = 1.5707963267948966;

  /// How far a frame stands off the wall behind it.
  static const double frameStandoff = 0.14;

  /// How far anything painted on a wall sits proud of it.
  ///
  /// Must clear *half* the wall's thickness, not merely be positive: the
  /// walls are slabs centred on their nominal plane, so a sign nudged a few
  /// millimetres toward the room is still buried inside the wall and renders
  /// nowhere. This is the bug that hid the far wall's lettering completely.
  static const double wallThickness = 0.2;
  static const double paintedOnWall = wallThickness / 2 + 0.02;

  /// Frames are wider than they are tall, matching the artwork.
  static const double frameWidth = 4;

  /// How much wood shows around the card, on every side.
  ///
  /// A moulding, not a hairline. Too thin and the frame reads as a border
  /// drawn on the card rather than as a thing the card sits inside.
  static const double frameBorder = 0.22;

  /// How far the card stands proud of the wood behind it.
  ///
  /// Small, but not zero: two surfaces at the same depth fight for the same
  /// pixels and flicker as the camera moves.
  static const double cardRelief = 0.012;

  /// The floor and ceiling extend well past the walls so no edge is visible
  /// from inside.
  static const double groundSize = 200;

  /// How thick the ceiling slab is.
  ///
  /// Non-zero on purpose, and the reason is lighting rather than looks. A
  /// plane's vertex normals all point straight up, which is right for a floor
  /// and exactly wrong for a ceiling: the surface then faces away from the
  /// room, every light in the corridor sits behind it, and it shades black.
  /// The original dodged this by marking the ceiling double-sided, which
  /// flips the normal for back-facing fragments. With no such setting here,
  /// the ceiling is given a thickness instead, so it is a solid whose
  /// underside genuinely faces down.
  static const double ceilingThickness = 0.2;

  static List<Placement> build() {
    final length = GalleryDimensions.corridorLength;
    final centreZ = -length / 2;
    final height = GalleryDimensions.corridorHeight + 2;

    return <Placement>[
      Placement(
        kind: SurfaceKind.floor,
        position: Vector3(0, GalleryDimensions.floorY, centreZ),
        extents: Vector3(groundSize, 0, groundSize),
      ),
      Placement(
        kind: SurfaceKind.ceiling,
        // Raised by half its thickness so the face the visitor sees sits at
        // the ceiling height, not the middle of the slab.
        position: Vector3(
          0,
          GalleryDimensions.ceilY + ceilingThickness / 2,
          centreZ,
        ),
        extents: Vector3(groundSize, ceilingThickness, groundSize),
      ),
      // The left wall runs the whole corridor.
      Placement(
        kind: SurfaceKind.sideWall,
        position: Vector3(-GalleryDimensions.wallX, 0.5, centreZ),
        extents: Vector3(0.2, height, length + 4),
      ),

      // The right wall stops short, which is what opens the corridor into
      // the testimonial wing. Running it the full length walls the wing off
      // entirely, and the camera pans straight through it on its way there —
      // reading as the room turning inside out rather than as a corner.
      Placement(
        kind: SurfaceKind.sideWall,
        position: Vector3(
          GalleryDimensions.wallX,
          0.5,
          -GalleryDimensions.rightWallLength / 2 + 2,
        ),
        extents: Vector3(0.2, height, GalleryDimensions.rightWallLength),
      ),

      // The far wall spans the corridor *and* the wing beside it, rather than
      // being centred on the corridor — the testimonials hang along its
      // right-hand stretch.
      Placement(
        kind: SurfaceKind.backWall,
        position: Vector3(
          (GalleryDimensions.kbEntryX - GalleryDimensions.corridorWidth) / 2,
          0.5,
          GalleryDimensions.backWallZ,
        ),
        extents: Vector3(
          GalleryDimensions.kbEntryX + GalleryDimensions.corridorWidth,
          height,
          0.2,
        ),
      ),

      // The wall at the visitor's back while they read. Without it the wing
      // is a shelf hanging in the dark.
      Placement(
        kind: SurfaceKind.wingWall,
        position: Vector3(
          (GalleryDimensions.kbEntryX + GalleryDimensions.wallX) / 2,
          0.5,
          GalleryDimensions.backWallZ + GalleryDimensions.corridorWidth,
        ),
        extents: Vector3(
          GalleryDimensions.kbEntryX - GalleryDimensions.wallX,
          height,
          0.2,
        ),
      ),
      // Painted on the left wall before the first piece, where the original
      // put it — offered as the visitor arrives, not only at the far end.
      Placement(
        kind: SurfaceKind.exitSign,
        position: Vector3(
          -GalleryDimensions.wallX + paintedOnWall,
          GalleryDimensions.frameY,
          -1,
        ),
        extents: Vector3(1.7, 0.62, 0.02),
        rotationY: quarterTurn,
      ),
      ..._frames(GalleryProjects.left, onLeft: true),
      ..._frames(GalleryProjects.right, onLeft: false),
    ];
  }

  static Iterable<Placement> _frames(
    List<Project> projects, {
    required bool onLeft,
  }) sync* {
    for (var i = 0; i < projects.length; i++) {
      // Frames start one spacing in, so the first is not level with the
      // entrance where it would be edge-on and unreadable.
      final z = -(i + 1) * GalleryDimensions.spacing;
      final x = onLeft
          ? -GalleryDimensions.wallX + frameStandoff
          : GalleryDimensions.wallX - frameStandoff;

      yield Placement(
        kind: SurfaceKind.frame,
        position: Vector3(x, GalleryDimensions.frameY, z),
        extents: Vector3(
          frameWidth,
          GalleryDimensions.frameMaxHeight,
          GalleryDimensions.frameDepth * 0.3,
        ),
        rotationY: onLeft ? quarterTurn : -quarterTurn,
        project: projects[i],
      );
    }
  }
}
