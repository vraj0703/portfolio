import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/piece_art.dart';
import 'package:portfolio/domain/gallery/project_data.dart';

/// The seven drawings: each made from its project's facts, so the counts
/// are the facts, and none of them leaves the paper.
void main() {
  List<ArtMark> of(PieceArt art) => PieceDrawing.marks(art);

  group('the counts are the facts', () {
    test('Shunya Systems: five nodes, every one joined to every other', () {
      final marks = of(PieceArt.mesh);
      final nodes = marks.where(
        (m) => m.shape is ArtCircle && m.ink != ArtInk.faint,
      );
      expect(nodes, hasLength(5));
      // Every pair once: five choose two.
      expect(marks.where((m) => m.shape is ArtLine), hasLength(10));
      // One of them, where the plans are made, in the accent.
      expect(nodes.where((m) => m.ink == ArtInk.accent), hasLength(1));
    });

    test('tantr app: five squares, one inside the next, each turned', () {
      final squares = of(PieceArt.nested).where((m) => m.shape is ArtBox);
      expect(squares, hasLength(5));
      final turns = squares.map((m) => (m.shape as ArtBox).turn).toList();
      expect(turns, <double>[0, 11, 22, 33, 44]);
    });

    test('Publications: twelve points on one thread', () {
      final marks = of(PieceArt.constellation);
      final points = marks.where((m) => m.shape is! ArtPolyline);
      expect(points, hasLength(12));
      expect(marks.where((m) => m.shape is ArtPolyline), hasLength(1));
      expect((marks.first.shape as ArtPolyline).points, hasLength(12));
      // Six discs, five diamonds, one accent disc.
      expect(points.where((m) => m.ink == ArtInk.fill), hasLength(6));
      expect(points.where((m) => m.ink == ArtInk.hollow), hasLength(5));
      expect(points.where((m) => m.ink == ArtInk.accent), hasLength(1));
    });

    test('Twin Health: sixty-seven strokes, the last in the accent', () {
      final strokes = of(PieceArt.tally)
          .where((m) => m.ink == ArtInk.line3 || m.ink == ArtInk.accentLine)
          .toList();
      expect(strokes, hasLength(67));
      expect(strokes.last.ink, ArtInk.accentLine);
      expect(strokes.take(66).every((m) => m.ink == ArtInk.line3), isTrue);
    });

    test('FieldAssist / PayU: three locks nested, the innermost accented', () {
      final locks = of(PieceArt.field).where((m) => m.shape is ArtBox).toList();
      expect(locks, hasLength(3));
      expect(locks.last.ink, ArtInk.accentLine);
      // The dot field keeps an oval clear at the centre; the inner two locks
      // sit wholly inside it (the outer one's corners reach the dots, as in
      // the mock).
      final dots = of(PieceArt.field).where((m) => m.shape is ArtCircle);
      expect(dots, isNotEmpty);
      final outer = (locks[1].shape as ArtBox).rect;
      for (final dot in dots) {
        expect(outer.contains((dot.shape as ArtCircle).centre), isFalse);
      }
    });

    test('the two pieces in preparation: seven rings, five brush lines', () {
      expect(of(PieceArt.rings).where((m) => m.shape is ArtArc), hasLength(7));
      expect(of(PieceArt.brush), hasLength(5));
    });
  });

  test('nothing is drawn outside the paper', () {
    // The field is the paper inside the mat; a mark that crossed it would be
    // cut by the mat or, worse, by the frame.
    final field = Offset.zero & PieceDrawing.field;
    for (final art in PieceArt.values) {
      for (final mark in of(art)) {
        final bounds = mark.bounds;
        expect(
          field.contains(bounds.topLeft) &&
              field.contains(bounds.bottomRight - const Offset(1e-6, 1e-6)),
          isTrue,
          reason: '$art: ${mark.shape.runtimeType} at $bounds',
        );
      }
    }
  });

  test('every piece has its own drawing', () {
    final arts = GalleryProjects.all.map((p) => p.art).toSet();
    expect(arts, hasLength(GalleryProjects.all.length));
  });
}
