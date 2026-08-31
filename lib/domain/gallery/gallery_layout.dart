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

  /// A wall of the skills hall, off the end of the testimonial wing.
  hallWall,

  /// The invitation cut beside the hall's door.
  connectSign,

  /// The radio's face, hung on the right wall by the entrance.
  radio,

  /// Its two controls: the one that opens the stream and the one that steps
  /// the dial. Separate kinds rather than one with an index, so a tap can be
  /// answered without asking which half of a panel it landed on.
  radioPlay,
  radioNext,

  /// How to handle the board, cut into the wall behind it.
  hallInstruction,

  /// One key on the skills board.
  keycap,

  /// A frame on the far wall, for a recommendation.
  ///
  /// Distinct from [frame] rather than another of them: these hang on a
  /// different wall in a different orientation, they carry no project, and
  /// they must stay out of the corridor's click-to-focus and its stepping
  /// order — a visitor pressing "next work" should not be sent to the far
  /// wall.
  testimonialFrame,
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
          GalleryDimensions.backWallZ + GalleryDimensions.wingWidth,
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
        // Half again as large as it was. An engraving has no fill to carry
        // it — it is read entirely by two thin edges — so where paint could
        // be small and still legible, a cut has to be big enough for its
        // edges to survive being seen across a corridor.
        extents: Vector3(2.6, 0.95, 0.02),
        rotationY: quarterTurn,
      ),
      ..._radio(),
      ..._skillHall(),
      ..._testimonialFrames(),
      ..._frames(GalleryProjects.left, onLeft: true),
      ..._frames(GalleryProjects.right, onLeft: false),
    ];
  }

  /// The radio, and the two things on it that can be pressed.
  ///
  /// On the right wall by the entrance, opposite the way out — the first
  /// thing the visitor passes on that side, where the previous site had it.
  /// Before the first picture, which starts a full spacing in, so it has the
  /// wall to itself.
  static Iterable<Placement> _radio() sync* {
    yield* _radioAt(
      Vector3(
        GalleryDimensions.wallX - paintedOnWall,
        GalleryDimensions.frameY,
        radioZ,
      ),
      facing: -quarterTurn,
    );

    // A second one in the skills hall, on the entry wall opposite the
    // invitation. The visitor spends longer in that room than anywhere else
    // — the board is the one thing here they can play with — and walking
    // back to the corridor to change the station is the sort of errand a
    // room should not send anybody on.
    final segment =
        (GalleryDimensions.kbWidth - GalleryDimensions.wingWidth) / 2;

    yield* _radioAt(
      Vector3(
        GalleryDimensions.kbEntryX + paintedOnWall,
        // Level with the invitation across the door, not with the corridor's
        // pictures. The two are a pair flanking the way in, and a pair at
        // different heights reads as two things that happen to be on the
        // same wall.
        //
        // Level by the *station name*, not by the panel. The invitation is
        // one line and the radio is four, so matching their centres puts
        // LET'S CONNECT alongside the radio's second row and its name up in
        // the air above — which is what the hall looked like, and why this
        // still read as misaligned after the heights already matched.
        GalleryDimensions.connectSignY - radioStationDrop,
        // The far side of the door from the invitation, which hangs at
        // *minus* this. One on each side of the way in.
        GalleryDimensions.kbZ + (GalleryDimensions.wingWidth + segment) / 2,
      ),
      facing: quarterTurn,
    );
  }

  /// One radio, and the two things on it that can be pressed.
  ///
  /// [facing] turns the whole assembly, and the controls are offset along the
  /// wall *after* it — which is why they are expressed as a distance from the
  /// panel's own middle rather than as world coordinates. Written out per
  /// wall, the second radio's buttons would be a sign error away from being
  /// unreachable.
  static Iterable<Placement> _radioAt(
    Vector3 panel, {
    required double facing,
  }) sync* {
    yield Placement(
      kind: SurfaceKind.radio,
      position: panel,
      extents: Vector3(radioWidth, radioHeight, 0.02),
      rotationY: facing,
    );

    // Which way along the wall "left of the middle" runs depends on which
    // way the panel faces, and the drawn face is mirrored with it — so the
    // offsets turn with the panel. Without this the STOP button on one of
    // the two radios would be where NEXT is drawn.
    final along = facing > 0 ? -1.0 : 1.0;

    for (final control in <(SurfaceKind, double)>[
      (SurfaceKind.radioPlay, -radioButtonSpacing / 2),
      (SurfaceKind.radioNext, radioButtonSpacing / 2),
    ]) {
      yield Placement(
        kind: control.$1,
        position: Vector3(
          panel.x,
          panel.y - radioButtonDrop,
          panel.z + control.$2 * along,
        ),
        extents: Vector3(radioButtonSize, radioButtonSize, 0.02),
        rotationY: facing,
      );
    }
  }

  /// The room the keyboard hangs in, and the passage into it.
  ///
  /// A square hall at the end of the testimonial wing, walled on three sides
  /// with the fourth left open in the middle so the visitor can walk through.
  /// That opening is why the entry side is two pieces rather than one: a
  /// single wall across it would seal the hall off, and the camera would
  /// arrive facing plaster.
  static Iterable<Placement> _skillHall() sync* {
    final height = GalleryDimensions.corridorHeight + 2;
    final width = GalleryDimensions.kbWidth;
    final depth = GalleryDimensions.kbDepth;
    final x = GalleryDimensions.kbX;
    final z = GalleryDimensions.kbZ;

    Placement wall(Vector3 position, Vector3 extents) => Placement(
      kind: SurfaceKind.hallWall,
      position: position,
      extents: extents,
    );

    // The two sides running away from the corridor, and the far end. The
    // sides run the room's *depth*; the far wall spans its width.
    yield wall(
      Vector3(x, 0.5, z + width / 2),
      Vector3(depth, height, wallThickness),
    );
    yield wall(
      Vector3(x, 0.5, z - width / 2),
      Vector3(depth, height, wallThickness),
    );
    yield wall(
      Vector3(GalleryDimensions.kbEndX, 0.5, z),
      Vector3(wallThickness, height, width),
    );

    // The entry side, in two pieces with the passage between them. The
    // opening is exactly the alley's cross-section, so walking out of the
    // alley is walking through the door — anything wider would show the
    // hall's own walls from inside the alley, and anything narrower would
    // make the visitor thread a gap they cannot see the sides of.
    final segment = (width - GalleryDimensions.wingWidth) / 2;
    for (final side in <double>[-1, 1]) {
      yield wall(
        Vector3(
          GalleryDimensions.kbEntryX,
          0.5,
          z + side * (GalleryDimensions.wingWidth + segment) / 2,
        ),
        Vector3(wallThickness, height, segment),
      );
    }

    // Cut into the far wall, above and behind the board. The visitor meets
    // the hall facing this way — they walk in along `+x` and the board is
    // what they came for — so this is the one wall they are certain to be
    // looking at, and the only one an instruction can be counted on to be
    // read from.
    yield Placement(
      kind: SurfaceKind.hallInstruction,
      position: Vector3(
        GalleryDimensions.kbEndX - paintedOnWall,
        GalleryDimensions.instructionY,
        z,
      ),
      // Wide, and taller than it looks it needs: the face is nine times
      // wider than it is high, so the type inside it is small before it is
      // anything else.
      extents: Vector3(6.4, 0.85, 0.02),
      // Faces back down the hall, toward the door the visitor came through.
      rotationY: -quarterTurn,
    );

    // Painted on the entry wall, inside the hall, on the segment to the
    // visitor's right as they stand at the board and turn back toward the
    // door. It faces `+x` because that is the way into the room: with their
    // back to the board is the one moment they are looking at this wall at
    // all.
    //
    // The right-hand segment is the one at *smaller* z. The visitor came in
    // along `+x`, so turning to face the door turns them about — and the
    // side that was on their left walking in is the side on their right
    // looking back.
    yield Placement(
      kind: SurfaceKind.connectSign,
      position: Vector3(
        GalleryDimensions.kbEntryX + paintedOnWall,
        GalleryDimensions.connectSignY,
        z - (GalleryDimensions.wingWidth + segment) / 2,
      ),
      extents: Vector3(3.8, 1.05, 0.02),
      rotationY: quarterTurn,
    );
  }

  /// Where the radio hangs, and how big its face is.
  ///
  /// Level with the pictures and mirroring the way out on the far wall: one
  /// object each side of the entrance, at the same height, so the corridor
  /// opens with a pair rather than with something lopsided.
  static const double radioZ = -1;
  static const double radioWidth = 2;
  static const double radioHeight = 1.3;

  /// Where the two controls sit on the face, as fractions of it.
  ///
  /// Fractions, and *shared with the drawing* — `RadioFace` reads these to
  /// decide where to letter PLAY and NEXT, and the tap targets below are
  /// derived from the same two numbers. They were briefly a separate pair,
  /// and the drawn buttons ended up an eighth of a metre from the places
  /// they could actually be pressed: a picture and a promise about where a
  /// finger has to land, quietly disagreeing.
  ///
  /// [radioControlsAt] is measured down from the top of the face, the way an
  /// image is; the placements convert it.
  static const double radioControlsAt = 0.786;
  static const double radioControlOffset = 0.155;

  /// Where the station's own line sits on the face, the same way.
  ///
  /// Needed because the face is *four rows centred as a block*, so its
  /// loudest line — the station name — does not sit at the panel's middle.
  /// Hanging the panel at the invitation's height therefore lines up two
  /// things nobody looks at, and leaves the two names visibly out of step.
  /// This is what lets a radio be hung by its name instead.
  static const double radioStationAt = 0.2675;

  /// How far to lower a radio so its station name lands at a given height.
  ///
  /// Positive: the name sits above the panel's middle, so the panel goes
  /// below the line it is being aligned to.
  static const double radioStationDrop =
      (0.5 - radioStationAt) * radioHeight;

  /// How big a target each control is.
  ///
  /// Square and generous — larger than the lettering on it. A control the
  /// size of its own label is a control that has to be aimed at, and this
  /// one is read at an angle from across a corridor.
  static const double radioButtonSize = 0.42;

  /// The controls' offsets in world units, from the middle of the face.
  static const double radioButtonSpacing =
      radioControlOffset * 2 * radioWidth;
  static const double radioButtonDrop =
      (radioControlsAt - 0.5) * radioHeight;

  /// How far a far-wall frame stands off the plaster.
  ///
  /// Must clear half the wall's thickness before anything else: the back wall
  /// is a slab centred on its plane, so a frame nudged a few millimetres
  /// toward the room is still inside it.
  static double get testimonialStandoff =>
      paintedOnWall + GalleryDimensions.frameDepth * 0.3 / 2;

  /// The row of frames along the far wall.
  ///
  /// Unrotated, unlike the corridor's. The far wall faces down the corridor
  /// already, so these span `x` and need no quarter turn — giving them one
  /// would stand them edge-on to the only place anyone looks at them from.
  static Iterable<Placement> _testimonialFrames() sync* {
    for (var i = 0; i < GalleryDimensions.testimonialCount; i++) {
      yield Placement(
        kind: SurfaceKind.testimonialFrame,
        position: Vector3(
          GalleryDimensions.testStartX + i * GalleryDimensions.testSpacing,
          GalleryDimensions.frameY,
          GalleryDimensions.backWallZ + testimonialStandoff,
        ),
        extents: Vector3(
          frameWidth,
          GalleryDimensions.frameMaxHeight,
          GalleryDimensions.frameDepth * 0.3,
        ),
      );
    }
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
