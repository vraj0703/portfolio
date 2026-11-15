import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

/// The drawing each piece carries, made from the project's own facts.
///
/// Ported from `docs/frames-as-pieces/art.py`, which is the reference Vishal
/// judged in the mock: same coordinates, same counts, on the same 400 x 500
/// field. The drawings are data here, not paint calls, so a test can count
/// the nodes and check that nothing leaves the paper without rasterising a
/// pixel; `PieceCard` turns them into ink.
enum PieceArt {
  /// Shunya Systems: five nodes, every one joined to every other.
  mesh,

  /// tantr app: five rounded squares, one inside the next.
  nested,

  /// Publications: twelve points on one thread.
  constellation,

  /// Twin Health: sixty-seven upright strokes, one per release.
  tally,

  /// FieldAssist / PayU: a dot field around three nested locks.
  field,

  /// School and College: growth rings.
  rings,

  /// Creative Works: five brush lines.
  brush,
}

/// How a mark is inked, after the mock's classes.
enum ArtInk {
  /// `a-line`: an ink stroke, 2 wide.
  line,

  /// `a-line w2`: 3 wide.
  line2,

  /// `a-line w3`: 4 wide.
  line3,

  /// `a-faint`: an ink stroke 1 wide, at 28%.
  faint,

  /// `a-fill`: solid ink.
  fill,

  /// `a-hollow`: paper inside, an ink edge 2 wide.
  hollow,

  /// `a-accent`: solid accent.
  accent,

  /// `a-accent-line`: an accent stroke, 5 wide.
  accentLine,
}

/// One mark of a drawing: a shape, and how it is inked.
///
/// [width] overrides the ink's own stroke width, for the brush lines, whose
/// weights vary line to line.
class ArtMark {
  const ArtMark(this.shape, this.ink, {this.width});

  final ArtShape shape;
  final ArtInk ink;
  final double? width;

  /// How wide its stroke is, or 0 when it is only filled.
  double get strokeWidth =>
      width ??
      switch (ink) {
        ArtInk.line || ArtInk.hollow => 2,
        ArtInk.line2 => 3,
        ArtInk.line3 => 4,
        ArtInk.faint => 1,
        ArtInk.accentLine => 5,
        ArtInk.fill || ArtInk.accent => 0,
      };

  /// Everything the mark covers on the field, its stroke included.
  Rect get bounds => shape.path().getBounds().inflate(strokeWidth / 2);
}

/// The geometry of a mark, on the 400 x 500 field.
sealed class ArtShape {
  const ArtShape();

  /// The outline, for painting and for measuring.
  Path path();
}

class ArtLine extends ArtShape {
  const ArtLine(this.from, this.to);
  final Offset from;
  final Offset to;

  @override
  Path path() => Path()
    ..moveTo(from.dx, from.dy)
    ..lineTo(to.dx, to.dy);
}

class ArtCircle extends ArtShape {
  const ArtCircle(this.centre, this.radius);
  final Offset centre;
  final double radius;

  @override
  Path path() =>
      Path()..addOval(Rect.fromCircle(center: centre, radius: radius));
}

/// A rounded rectangle, turned [turn] degrees about [pivot] (SVG's
/// `rotate(a cx cy)`, clockwise on screen).
class ArtBox extends ArtShape {
  const ArtBox(this.rect, {this.radius = 0, this.turn = 0, this.about});
  final Rect rect;
  final double radius;
  final double turn;

  /// The point turned about; the box's own centre when null.
  final Offset? about;

  Offset get pivot => about ?? rect.center;

  @override
  Path path() {
    final box = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    if (turn == 0) return box;
    final a = turn * math.pi / 180;
    final c = math.cos(a), s = math.sin(a);
    final p = pivot;
    // Rotation about the pivot, column-major for Path.transform.
    final m = Float64List.fromList(<double>[
      c, s, 0, 0, //
      -s, c, 0, 0, //
      0, 0, 1, 0, //
      p.dx - c * p.dx + s * p.dy, p.dy - s * p.dx - c * p.dy, 0, 1,
    ]);
    return box.transform(m);
  }
}

class ArtPolyline extends ArtShape {
  const ArtPolyline(this.points);
  final List<Offset> points;

  @override
  Path path() => Path()..addPolygon(points, false);
}

/// SVG's `A r r 0 0 1`: the short arc from [from] to [to], clockwise.
class ArtArc extends ArtShape {
  const ArtArc(this.from, this.to, this.radius);
  final Offset from;
  final Offset to;
  final double radius;

  @override
  Path path() => Path()
    ..moveTo(from.dx, from.dy)
    ..arcToPoint(to, radius: Radius.circular(radius));
}

/// SVG's `M a C b c d S e f`: two cubics, the second's first control point
/// the reflection of the first's last about the join.
class ArtWave extends ArtShape {
  const ArtWave(this.start, this.c1, this.c2, this.mid, this.c4, this.end);
  final Offset start, c1, c2, mid, c4, end;

  @override
  Path path() {
    final c3 = mid * 2 - c2;
    return Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, mid.dx, mid.dy)
      ..cubicTo(c3.dx, c3.dy, c4.dx, c4.dy, end.dx, end.dy);
  }
}

/// The seven drawings, as marks on the field.
abstract final class PieceDrawing {
  /// The field every drawing is laid out on.
  static const Size field = Size(400, 500);

  /// [art]'s marks, in the order they are drawn.
  static List<ArtMark> marks(PieceArt art) => switch (art) {
    PieceArt.mesh => _mesh(),
    PieceArt.nested => _nested(),
    PieceArt.constellation => _constellation(),
    PieceArt.tally => _tally(),
    PieceArt.field => _field(),
    PieceArt.rings => _rings(),
    PieceArt.brush => _brush(),
  };

  static List<ArtMark> _mesh() {
    const pts = <Offset>[
      Offset(200, 96),
      Offset(330, 205),
      Offset(282, 380),
      Offset(118, 380),
      Offset(70, 205),
    ];
    return <ArtMark>[
      const ArtMark(ArtCircle(Offset(200, 250), 176), ArtInk.faint),
      for (var i = 0; i < 5; i++)
        for (var j = i + 1; j < 5; j++)
          ArtMark(ArtLine(pts[i], pts[j]), ArtInk.line),
      for (var i = 0; i < 5; i++)
        ArtMark(
          ArtCircle(pts[i], i == 0 ? 15 : 9),
          i == 0 ? ArtInk.accent : ArtInk.fill,
        ),
    ];
  }

  static List<ArtMark> _nested() => <ArtMark>[
    for (var i = 0; i < 5; i++)
      ArtMark(
        ArtBox(
          Rect.fromCenter(
            center: const Offset(200, 250),
            width: 300.0 - i * 52,
            height: 300.0 - i * 52,
          ),
          radius: 18.0 - i * 2,
          turn: i * 11.0,
          about: const Offset(200, 250),
        ),
        ArtInk.line2,
      ),
    const ArtMark(ArtCircle(Offset(200, 250), 20), ArtInk.accent),
  ];

  static List<ArtMark> _constellation() {
    final pts = <Offset>[
      for (var i = 0; i < 12; i++)
        Offset(
          200 + (34 + 13.5 * i) * math.cos(i * 2.39996 + 0.6) * 0.86,
          250 + (34 + 13.5 * i) * math.sin(i * 2.39996 + 0.6) * 1.05,
        ),
    ];
    return <ArtMark>[
      ArtMark(ArtPolyline(pts), ArtInk.line),
      for (var i = 0; i < 12; i++)
        if (i == 11)
          ArtMark(ArtCircle(pts[i], 15), ArtInk.accent)
        else if (i.isEven)
          ArtMark(ArtCircle(pts[i], 8), ArtInk.fill)
        else
          ArtMark(
            ArtBox(Rect.fromCenter(center: pts[i], width: 14, height: 14),
                turn: 45),
            ArtInk.hollow,
          ),
    ];
  }

  static List<ArtMark> _tally() => <ArtMark>[
    for (var i = 0; i < 67; i++)
      ArtMark(
        ArtLine(
          Offset(74.0 + (i % 10) * 28, 76.0 + (i ~/ 10) * 54),
          Offset(74.0 + (i % 10) * 28, 76.0 + (i ~/ 10) * 54 + 36),
        ),
        i == 66 ? ArtInk.accentLine : ArtInk.line3,
      ),
    for (var row = 0; row < 7; row++)
      ArtMark(
        ArtLine(
          Offset(62, 76.0 + row * 54 + 44),
          Offset(74.0 + ((row < 6 ? 10 : 7) - 1) * 28 + 12, 76.0 + row * 54 + 44),
        ),
        ArtInk.faint,
      ),
  ];

  static List<ArtMark> _field() => <ArtMark>[
    for (var r = 0; r < 20; r++)
      for (var c = 0; c < 16; c++)
        if (math.pow(50 + c * 20 - 200, 2) / (100 * 100) +
                math.pow(60 + r * 20 - 250, 2) / (124 * 124) >=
            1)
          ArtMark(
            ArtCircle(Offset(50.0 + c * 20, 60.0 + r * 20), 2.4),
            ArtInk.fill,
          ),
    for (final (i, k) in const <double>[1, 0.68, 0.36].indexed)
      ArtMark(
        ArtBox(
          Rect.fromLTWH(200 - 86 * k, 250 - 108 * k, 172 * k, 216 * k),
          radius: 26 * k,
        ),
        i == 2 ? ArtInk.accentLine : ArtInk.line2,
      ),
  ];

  static List<ArtMark> _rings() => <ArtMark>[
    for (var i = 0; i < 7; i++)
      ArtMark(
        ArtArc(
          _onCircle(const Offset(200, 330), 34.0 + i * 26, 200.0 - i * 9),
          _onCircle(const Offset(200, 330), 34.0 + i * 26, -20.0 + i * 9),
          34.0 + i * 26,
        ),
        ArtInk.line2,
      ),
    const ArtMark(ArtCircle(Offset(200, 330), 9), ArtInk.accent),
  ];

  static List<ArtMark> _brush() => <ArtMark>[
    for (var i = 0; i < 5; i++)
      ArtMark(
        ArtWave(
          Offset(48, 130.0 + i * 62),
          Offset(130, 130.0 + i * 62 - (46 - i * 5)),
          Offset(150, 130.0 + i * 62 + (46 - i * 5)),
          Offset(200, 130.0 + i * 62),
          Offset(300, 130.0 + i * 62 - (46 - i * 5)),
          Offset(352, 130.0 + i * 62),
        ),
        i == 2 ? ArtInk.accentLine : ArtInk.line,
        width: 3.0 + (i * 7) % 9,
      ),
  ];

  static Offset _onCircle(Offset c, double r, double degrees) {
    final a = degrees * math.pi / 180;
    return Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
  }
}
