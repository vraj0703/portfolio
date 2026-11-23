import 'dart:math' as math;

/// The CSS matrix3d that maps a page of [width] x [height] onto four points
/// on the screen (PORTFOLIO-6, the live-in-the-corridor prototype): the way
/// three.js's CSS3DRenderer lays a DOM element on a plane in perspective.
///
/// [corners] are the card's corners on the screen in the page's own order:
/// top-left, top-right, bottom-right, bottom-left (x, y pairs). Returns the
/// 16 column-major numbers of `matrix3d(...)`, or null when the four points
/// do not make a quad the page can be mapped onto.
List<double>? cardMatrix3d({
  required double width,
  required double height,
  required List<(double, double)> corners,
}) {
  if (corners.length != 4) return null;
  // The projective map from the unit square to the quad (Heckbert's
  // square-to-quad), then scaled by the page's size.
  final (x0, y0) = corners[0];
  final (x1, y1) = corners[1];
  final (x2, y2) = corners[2];
  final (x3, y3) = corners[3];
  final dx1 = x1 - x2, dx2 = x3 - x2, dx3 = x0 - x1 + x2 - x3;
  final dy1 = y1 - y2, dy2 = y3 - y2, dy3 = y0 - y1 + y2 - y3;
  final den = dx1 * dy2 - dx2 * dy1;
  if (den.abs() < 1e-9) return null;
  final g = (dx3 * dy2 - dx2 * dy3) / den;
  final h = (dx1 * dy3 - dx3 * dy1) / den;
  final a = x1 - x0 + g * x1;
  final b = x3 - x0 + h * x3;
  final c = x0;
  final d = y1 - y0 + g * y1;
  final e = y3 - y0 + h * y3;
  final f = y0;
  // Unit square -> page: divide the u, v columns by the page's size.
  final aw = a / width, bh = b / height;
  final dw = d / width, eh = e / height;
  final gw = g / width, hh = h / height;
  if (![aw, bh, dw, eh, gw, hh, c, f].every((v) => v.isFinite)) return null;
  // matrix3d, column-major: the 3x3 (x, y, w) projective map lifted to 4x4.
  return <double>[
    aw, dw, 0, gw, //
    bh, eh, 0, hh, //
    0, 0, 1, 0, //
    c, f, 0, 1, //
  ];
}

/// Where the page point ([u], [v]) lands under [m] (for tests).
(double, double) applyMatrix3d(List<double> m, double u, double v) {
  final x = m[0] * u + m[4] * v + m[12];
  final y = m[1] * u + m[5] * v + m[13];
  final w = m[3] * u + m[7] * v + m[15];
  return (x / w, y / w);
}

/// The quad's signed area (positive when its corners run clockwise on the
/// screen, as a card facing the camera does): a frame seen from behind or
/// edge-on is not drawn.
double quadArea(List<(double, double)> c) {
  var s = 0.0;
  for (var i = 0; i < c.length; i++) {
    final (x0, y0) = c[i];
    final (x1, y1) = c[(i + 1) % c.length];
    s += x0 * y1 - x1 * y0;
  }
  return s / 2;
}

/// The share of a [viewW] x [viewH] screen the quad covers (for the hybrid:
/// the picture while small, the live page once large).
double quadShare(List<(double, double)> c, double viewW, double viewH) =>
    math.max(0, quadArea(c)).toDouble() / (viewW * viewH);

/// The share rule (the hybrid): how far the live page is faded in over the
/// picture when the card covers [share] of the screen. None below [from],
/// all of it from [full] on, linear between, so it never pops.
double corridorOpacity(
  double share, {
  required double from,
  required double full,
}) {
  if (share <= from) return 0;
  if (share >= full) return 1;
  return (share - from) / (full - from);
}

/// Where the corridor's live page goes this frame, and how strongly.
class CorridorPlacement {
  const CorridorPlacement({required this.matrix, required this.opacity});

  /// Column-major matrix3d laying the page onto the card.
  final List<double> matrix;

  /// Over the picture: 0 none, 1 all.
  final double opacity;
}

/// The live page's placement for a card whose corners the camera projected
/// to [corners]: its two top corners, then its two bottom ones, each null
/// when that corner is behind the camera. Null (the page hidden, the picture
/// showing) when any corner is behind the camera, when the card is not
/// [facing] the camera, when the corners make no quad, or when the card is
/// too small on the [viewWidth] x [viewHeight] screen by the share rule.
CorridorPlacement? corridorPlacement({
  required List<(double, double)?> corners,
  required bool facing,
  required double viewWidth,
  required double viewHeight,
  required double pageWidth,
  required double pageHeight,
  required double shareFrom,
  required double shareFull,
}) {
  if (!facing || corners.length != 4 || corners.any((c) => c == null)) {
    return null;
  }
  final points = corners.cast<(double, double)>();
  // Each pair left to right on the screen: the page's own order, top-left,
  // top-right, bottom-right, bottom-left.
  final top = points.sublist(0, 2)..sort((a, b) => a.$1.compareTo(b.$1));
  final bottom = points.sublist(2)..sort((a, b) => a.$1.compareTo(b.$1));
  final quad = <(double, double)>[top[0], top[1], bottom[1], bottom[0]];
  if (quadArea(quad) <= 0) return null;
  final opacity = corridorOpacity(
    quadShare(quad, viewWidth, viewHeight),
    from: shareFrom,
    full: shareFull,
  );
  if (opacity <= 0) return null;
  final matrix = cardMatrix3d(
    width: pageWidth,
    height: pageHeight,
    corners: quad,
  );
  if (matrix == null) return null;
  return CorridorPlacement(matrix: matrix, opacity: opacity);
}
