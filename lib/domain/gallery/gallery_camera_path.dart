import 'dart:math' as math;

import 'package:vector_math/vector_math.dart';

import 'gallery_dimensions.dart';
import 'keyboard_layout.dart';

/// Where the camera is and what it is looking at, at a point in the walk.
class CameraPose {
  const CameraPose({required this.position, required this.target});

  final Vector3 position;
  final Vector3 target;
}

/// The camera's route through the gallery, as a pure function of progress.
///
/// Three movements, not one: the visitor walks the length of the corridor
/// looking straight ahead; then — once the far wall is close enough to read —
/// turns to it and tracks sideways along the testimonials; and then carries
/// on past the end of that wall, through the passage, into the hall where the
/// keyboard hangs. Splitting them is what makes the space feel like a room
/// rather than a rail; a single interpolated path would cut the corner and
/// clip the wall.
///
/// The hall is reached by scrolling rather than by pressing anything, so the
/// whole gallery is one continuous gesture from the entrance to the last
/// exhibit. That works because of an alignment the corridor already had: the
/// wall pan runs at `wallLockZ`, and the hall's centre line sits at exactly
/// the same depth, so the way in is straight ahead of where the pan stops.
/// If those two ever diverge this path needs a dogleg, and
/// `the pan ends on the hall's centre line` is the test that will say so.
///
/// Kept as maths rather than state so the whole route can be inspected at any
/// point without walking it, and so the handover between the two movements
/// can be tested for continuity — the one place a two-part path visibly
/// breaks.
abstract final class GalleryCameraPath {
  /// How the scroll is shared between the three movements.
  ///
  /// The corridor and the pan keep the lengths they had before the hall
  /// existed — [GalleryView.scrollExtent] grew to make room rather than the
  /// earlier stages being squeezed, so the pacing of everything already
  /// tuned is untouched.
  static const double walkFraction = 0.435;
  static const double panFraction = 0.315;
  static const double hallFraction = 0.25;

  /// Where each movement gives way to the next.
  static const double panEnd = walkFraction + panFraction;

  /// Eye height. Slightly below the frames' centre, so the work is read
  /// looking very slightly up — the way it hangs in a real room.
  static const double eyeHeight = 0.5;

  /// Where the visitor starts, just inside the entrance.
  static const double startZ = 3;

  /// How far ahead the camera looks while walking.
  static const double lookAhead = 10;

  /// How much of the walk is spent turning attention to the far wall.
  ///
  /// Expressed as a fraction of the walk rather than of the whole scroll.
  /// It used to be written in absolute progress — start at 0.45, finish at
  /// 0.58 — which silently stopped working the moment the hall pushed the
  /// walk's end to 0.435: every one of those comparisons went negative, the
  /// swing never happened, and the walk handed over to the pan mid-stride
  /// looking down an empty corridor.
  static const double approachShare = 0.224;

  /// Eye height for the wall pan, raised a touch to centre the cards.
  static const double panEyeHeight = 0.6;

  /// Where the camera stops along the back wall.
  static double get panEndX => GalleryDimensions.testPanEndX;

  /// How far short of the board the approach stops.
  ///
  /// Close enough to read the legends, far enough that the board is a whole
  /// object rather than a wall of keys.
  /// Shortened with the room. It also has to leave the visitor enough floor
  /// between the doorway and the stop for the turn to happen over: at 5.3 in
  /// a fourteen-unit hall they were barely two units past the threshold and
  /// the whole turn was crammed into it.
  static const double hallViewDistance = 3.5;

  /// How far above the board the eye ends up.
  ///
  /// Looking slightly down, the way anyone looks at a keyboard. Level with it
  /// the caps are edge-on and the rows collapse into one another.
  static const double hallEyeRise = 1.64;

  /// The hall stretch, in three beats.
  ///
  /// Reaching the doorway and turning to face in; holding there while the
  /// board rises; then walking to meet it.
  ///
  /// The hold is what the first attempt was missing. The board rose during
  /// the walk *to* the doorway — while the camera was still tracking the far
  /// wall, facing ninety degrees away from the hall — so the entrance
  /// happened where nobody could see it and the board was simply already
  /// standing there by the time anyone looked. The turn now completes before
  /// the rise begins.
  static const double doorwayShare = 0.35;
  static const double revealShare = 0.3;
  static double get revealStart => doorwayShare;
  static double get revealEnd => doorwayShare + revealShare;

  /// The scroll position at which the board actually starts to move.
  ///
  /// [revealStart] is a share *of the hall*, not of the whole walk, and the
  /// difference is nearly a tenth of the scroll — which is a second or two
  /// of the visitor standing in a doorway listening to a sound describing
  /// something that has not happened yet. Anything hung off the board
  /// beginning to rise reads this rather than doing that arithmetic again.
  static double get revealBegins => panEnd + revealStart * hallFraction;

  /// The camera's resting elevation above the board, in radians.
  ///
  /// Derived rather than stated, so the orbit's rest pose is the same place
  /// the approach ends and the two cannot drift apart.
  static double get hallRestElevation =>
      math.atan2(hallEyeRise, hallViewDistance);

  /// Distance from the board at rest, along the line of sight.
  static double get hallOrbitRadius =>
      math.sqrt(hallViewDistance * hallViewDistance + hallEyeRise * hallEyeRise);

  /// Where the camera stands when orbiting the board.
  ///
  /// The original let the visitor orbit the *camera* around a fixed board,
  /// and that is what gives the room its parallax: the walls slide past at
  /// their own rate while the board stays put, which is what tells the eye
  /// the board is an object in a place rather than a picture of one. Turning
  /// the board instead moves nothing but the board, and the room behind it
  /// sits dead still.
  static CameraPose orbitPose(double azimuth, double elevation) {
    final board = KeyboardLayout.anchor;
    final r = hallOrbitRadius;
    final flat = r * math.cos(elevation);

    return CameraPose(
      // Azimuth zero is the doorway, so the visitor's first sight of the
      // board is the pose the approach hands over at.
      position: Vector3(
        board.x - flat * math.cos(azimuth),
        board.y + r * math.sin(elevation),
        board.z + flat * math.sin(azimuth),
      ),
      target: Vector3(board.x, board.y, board.z),
    );
  }

  /// The pose at [progress], `0`..`1`.
  static CameraPose poseAt(double progress) {
    final p = progress.clamp(0.0, 1.0);
    if (p < walkFraction) return _walk(p);
    if (p < panEnd) return _pan(p);
    return _approach(p);
  }

  /// Down the corridor, looking straight ahead.
  ///
  /// The look target swings from "far down the corridor" to "the back wall"
  /// over the last stretch, so arriving at the end is a turn of attention
  /// rather than a stop. Squared, so the swing is imperceptible until the
  /// wall is genuinely close.
  static CameraPose _walk(double p) {
    final t = p / walkFraction;
    final z = startZ - t * (startZ - GalleryDimensions.wallLockZ);

    final proximity = ((t - (1 - approachShare)) / approachShare)
        .clamp(0.0, 1.0);
    final aheadZ = z - lookAhead;
    final lookZ =
        aheadZ + (GalleryDimensions.backWallZ - aheadZ) * proximity * proximity;

    // The eye rises to the pan's height over the same approach, so the two
    // movements meet at the same point rather than stepping. The original
    // relied on camera damping to smooth that step; making the path itself
    // continuous means it holds however the camera is driven.
    final eye = eyeHeight + (panEyeHeight - eyeHeight) * proximity;

    return CameraPose(
      position: Vector3(0, eye, z),
      target: Vector3(0, eye, lookZ),
    );
  }

  /// Sideways along the back wall, looking straight at it.
  ///
  /// Position and target share an x, so the wall is always viewed
  /// square-on. Letting the target lag would skew every card as it passed.
  static CameraPose _pan(double p) {
    final t = (p - walkFraction) / panFraction;
    final x = t * panEndX;

    return CameraPose(
      position: Vector3(x, panEyeHeight, GalleryDimensions.wallLockZ),
      target: Vector3(x, panEyeHeight, GalleryDimensions.backWallZ),
    );
  }

  /// On past the wall, through the passage, into the hall.
  ///
  /// The visitor keeps sidestepping — still facing the wall — until they
  /// reach the opening, and only then turns to face the room they are
  /// entering. Turning earlier would have them walk the last stretch of the
  /// wing looking at a wall they have already read, and turning later would
  /// put them inside the hall still facing out of it.
  static CameraPose _approach(double p) {
    final t = ((p - panEnd) / hallFraction).clamp(0.0, 1.0);
    final board = KeyboardLayout.anchor;
    final entry = GalleryDimensions.kbEntryX;
    final stopX = board.x - hallViewDistance;

    final double x;
    final double eyeY;
    final double turn;

    if (t < doorwayShare) {
      // To the doorway, turning from the wall to face into the hall as they
      // get there — so the board's entrance happens in front of them rather
      // than behind their shoulder.
      final u = t / doorwayShare;
      final ease = 1 - (1 - u) * (1 - u);
      x = panEndX + (entry - panEndX) * ease;
      eyeY = panEyeHeight;
      turn = u * u * (3 - 2 * u);
    } else if (t < revealEnd) {
      // Held at the threshold while the board rises.
      x = entry;
      eyeY = panEyeHeight;
      turn = 1;
    } else {
      final walk = (t - revealEnd) / (1 - revealEnd);
      final ease = 1 - (1 - walk) * (1 - walk);
      x = entry + (stopX - entry) * ease;
      eyeY = panEyeHeight + (board.y + hallEyeRise - panEyeHeight) * ease;
      turn = 1;
    }

    final wallAhead = Vector3(x, eyeY, GalleryDimensions.backWallZ);
    final look = wallAhead + (board - wallAhead) * turn;

    return CameraPose(
      position: Vector3(x, eyeY, GalleryDimensions.wallLockZ),
      target: look,
    );
  }

  /// How far the board has risen at [progress], `0`..`1`.
  ///
  /// Runs entirely within the hold at the doorway: nothing before the visitor
  /// has turned to face the hall, and finished before they set off to meet
  /// it, so the board is standing and still by the time they arrive.
  static double revealAt(double progress) {
    final t = ((progress - panEnd) / hallFraction).clamp(0.0, 1.0);
    return ((t - revealStart) / revealShare).clamp(0.0, 1.0);
  }
}
