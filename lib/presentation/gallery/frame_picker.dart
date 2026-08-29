import 'dart:ui' show Offset, Size;

import 'package:vector_math/vector_math.dart';

import 'package:portfolio/domain/gallery/gallery_layout.dart';
import 'package:portfolio/presentation/gallery/scene_axes.dart';

/// Projects a world point into the view, or null if it is behind the camera.
///
/// Injected rather than taken from a camera so the picking can be tested
/// without a GPU — the arithmetic is where the mistakes are, and a test
/// harness has no renderer to ask.
typedef Projector = Offset? Function(Vector3 world);

/// Which piece of work is under the pointer.
///
/// Screen-space rather than a raycast, deliberately. Every frame in this room
/// is a flat quad on a wall whose orientation is known from its placement, so
/// projecting four corners and testing a rectangle answers the question
/// exactly — with no pick metadata to thread through the scene graph, and no
/// dependence on a renderer to test it.
abstract final class FramePicker {
  /// The frame under [point], or null.
  ///
  /// Nearest-first when quads overlap on screen, which they do at a glancing
  /// angle down the corridor: without it a distant frame seen past the edge
  /// of a near one can win the hit, and clicking a piece sends the visitor to
  /// a different piece further away.
  static Placement? at(
    Offset point,
    Size viewSize,
    List<Placement> frames,
    Vector3 cameraPosition,
    Projector project, {
    Set<SurfaceKind> kinds = const <SurfaceKind>{SurfaceKind.frame},
  }) {
    Placement? best;
    var bestDistance = double.infinity;

    for (final frame in frames) {
      if (!kinds.contains(frame.kind)) continue;

      final bounds = _boundsOf(frame, project);
      if (bounds == null || !bounds.contains(point)) continue;

      final distance = cameraPosition.distanceToSquared(
        SceneAxes.position(frame.position),
      );
      if (distance < bestDistance) {
        bestDistance = distance;
        best = frame;
      }
    }

    return best;
  }

  /// The frame's screen rectangle, or null if any corner is behind the camera.
  ///
  /// All four corners are projected rather than the centre plus a radius: a
  /// perspective camera does not scale a quad evenly, and the near edge of a
  /// frame seen off-axis is markedly larger than the far one.
  static _Bounds? _boundsOf(Placement frame, Projector project) {
    var left = double.infinity;
    var top = double.infinity;
    var right = double.negativeInfinity;
    var bottom = double.negativeInfinity;

    for (final corner in cornersOf(frame)) {
      final screen = project(SceneAxes.position(corner));
      // One corner behind the camera makes the whole projection meaningless,
      // and clamping it would invent a rectangle the frame does not occupy.
      if (screen == null) return null;

      left = left < screen.dx ? left : screen.dx;
      right = right > screen.dx ? right : screen.dx;
      top = top < screen.dy ? top : screen.dy;
      bottom = bottom > screen.dy ? bottom : screen.dy;
    }

    return _Bounds(left, top, right, bottom);
  }

  /// The four corners of a frame, in design space.
  ///
  /// Frames are rotated a quarter turn so they face across the corridor,
  /// which puts their width along `z` and their height along `y`. Taking the
  /// width from `x` — the axis the extents nominally name — would describe a
  /// quad lying flat against the wall it hangs on.
  static List<Vector3> cornersOf(Placement frame) {
    // Taken from the placement rather than from a frame-shaped constant, so
    // anything flat on a wall can be picked — the way out is a quad too.
    final halfWidth = frame.extents.x / 2;
    final halfHeight = frame.extents.y / 2;
    final p = frame.position;

    // A keycap is not flat and does not stay put: the visitor can turn the
    // board it sits on, so no pair of axes stays square to the view. All
    // eight corners are projected and the screen rectangle taken around them
    // — slightly generous when the board is turned obliquely, which nothing
    // suffers from here because the caps are spaced wider than they are big
    // and the nearest one wins anyway.
    if (frame.kind == SurfaceKind.keycap) {
      final half = frame.extents / 2;
      return <Vector3>[
        for (final sx in <double>[-1, 1])
          for (final sy in <double>[-1, 1])
            for (final sz in <double>[-1, 1])
              Vector3(
                p.x + sx * half.x,
                p.y + sy * half.y,
                p.z + sz * half.z,
              ),
      ];
    }

    return <Vector3>[
      Vector3(p.x, p.y - halfHeight, p.z - halfWidth),
      Vector3(p.x, p.y - halfHeight, p.z + halfWidth),
      Vector3(p.x, p.y + halfHeight, p.z + halfWidth),
      Vector3(p.x, p.y + halfHeight, p.z - halfWidth),
    ];
  }
}

class _Bounds {
  const _Bounds(this.left, this.top, this.right, this.bottom);

  final double left;
  final double top;
  final double right;
  final double bottom;

  bool contains(Offset point) =>
      point.dx >= left &&
      point.dx <= right &&
      point.dy >= top &&
      point.dy <= bottom;
}
