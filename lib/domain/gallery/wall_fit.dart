import 'dart:math' as math;

/// How far from a wall the camera has to stand for a piece on it to fit the
/// screen, with a margin, whatever the screen's shape.
///
/// A fixed stop cannot serve both: the distance that frames the back wall's
/// statement on a 16:9 desktop leaves a portrait phone, which sees about a
/// third as wide, looking at the middle three words of it (Vishal,
/// 2026-11-18: want.png, not current.png). The fit is solved from the field
/// of view, on both axes, and the larger distance wins.
abstract final class WallFit {
  /// Space left either side of the piece, as a share of its width (and
  /// above and below, of its height). Vishal's want.png has the statement
  /// at about nine tenths of the screen's width.
  static const double margin = 0.06;

  /// The distance from the wall at which a piece [width] by [height] fills
  /// the view with [margin] to spare, for a vertical field of view [fovY]
  /// (radians) and a screen [aspect] (width over height).
  static double distance({
    required double width,
    required double height,
    required double aspect,
    required double fovY,
    double margin = WallFit.margin,
  }) {
    final halfY = math.tan(fovY / 2);
    final halfX = halfY * aspect;
    final across = width * (1 + 2 * margin) / 2 / halfX;
    final up = height * (1 + 2 * margin) / 2 / halfY;
    return math.max(across, up);
  }

  /// Whether a piece [width] wide, seen square-on from [distance], is whole
  /// on a screen of [aspect] with field of view [fovY].
  static bool fits({
    required double width,
    required double distance,
    required double aspect,
    required double fovY,
  }) => width / 2 <= distance * math.tan(fovY / 2) * aspect + 1e-9;
}
