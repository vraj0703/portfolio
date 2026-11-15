import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/gallery_dimensions.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';
import 'package:portfolio/domain/gallery/project_data.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/presentation/gallery/piece_card.dart';

/// A piece and its label, baked into one image.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const colors = DefaultAppColors();
  final layout = PieceCard.atlas();

  group('the image', () {
    test('holds the paper and the label side by side, apart', () {
      expect(layout.piece.overlaps(layout.label), isFalse);
      expect(layout.label.left - layout.piece.right, PieceCard.seam);
      final whole = Offset.zero & layout.size;
      expect(whole.contains(layout.piece.bottomRight - const Offset(1, 1)), isTrue);
      expect(whole.contains(layout.label.bottomRight - const Offset(1, 1)), isTrue);
    });

    test('each face is cut to the shape it is hung on', () {
      // The texture is stretched onto the face, so a region of another
      // shape would squash the drawing or the type.
      final paper = (GalleryLayout.pieceWidth - GalleryLayout.pieceBorder * 2) /
          (GalleryDimensions.frameMaxHeight - GalleryLayout.pieceBorder * 2);
      expect(layout.piece.width / layout.piece.height, closeTo(paper, 0.005));
      expect(
        layout.label.width / layout.label.height,
        closeTo(GalleryLayout.labelWidth / GalleryLayout.labelHeight, 0.005),
      );
    });

    test('costs no more pixels than the slide each frame used to carry', () {
      // PORTFOLIO-8: seven textures stay seven, and none grows. The old
      // card was 1024 x 736.
      final pixels = layout.size.width * layout.size.height;
      expect(pixels, lessThanOrEqualTo(1024 * 736));
    });

    test('a face samples exactly its own region', () {
      final share = layout.share(layout.label);
      expect(share.left * layout.size.width, closeTo(layout.label.left, 1e-9));
      expect(share.width * layout.size.width, closeTo(layout.label.width, 1e-9));
      expect(share.top, 0);
      expect(share.height * layout.size.height, closeTo(layout.label.height, 1e-9));
    });

    test('the drawing sits inside the mat, on every side', () {
      final field = PieceCard.fieldIn(layout.piece);
      final mat = layout.piece.width * PieceCard.mat;
      expect(field.left - layout.piece.left, greaterThanOrEqualTo(mat - 1e-9));
      expect(layout.piece.right - field.right, greaterThanOrEqualTo(mat - 1e-9));
      expect(field.top - layout.piece.top, greaterThanOrEqualTo(mat - 1e-9));
      expect(layout.piece.bottom - field.bottom, greaterThanOrEqualTo(mat - 1e-9));
      // 400 x 500, kept.
      expect(field.width / field.height, closeTo(0.8, 1e-9));
    });
  });

  group('baked', () {
    Future<(ByteData, int, int)> bake(Project p) async {
      final image = await PieceCard.render(project: p);
      final bytes = (await image.toByteData())!;
      final size = (image.width, image.height);
      image.dispose();
      return (bytes, size.$1, size.$2);
    }

    bool isPaper(ByteData b, int w, int x, int y) {
      final i = (y * w + x) * 4;
      final paper = colors.piecePaper;
      return (b.getUint8(i) - (paper.r * 255).round()).abs() < 3 &&
          (b.getUint8(i + 1) - (paper.g * 255).round()).abs() < 3 &&
          (b.getUint8(i + 2) - (paper.b * 255).round()).abs() < 3;
    }

    test('the image is the size of the layout', () async {
      final (_, w, h) = await bake(GalleryProjects.all.first);
      expect(w, layout.size.width.round());
      expect(h, layout.size.height.round());
    });

    test('the mat stays paper: no ink outside the field', () async {
      final field = PieceCard.fieldIn(layout.piece);
      for (final p in GalleryProjects.all) {
        final (bytes, w, _) = await bake(p);
        var inked = 0, outside = 0;
        for (var y = 0; y < layout.piece.height.round(); y += 2) {
          for (var x = 0; x < layout.piece.width.round(); x += 2) {
            final paper = isPaper(bytes, w, x, y);
            if (!paper) inked++;
            if (!paper && !field.inflate(1).contains(Offset(x + 0.5, y + 0.5))) {
              outside++;
            }
          }
        }
        expect(inked, greaterThan(0), reason: '${p.id}: nothing drawn');
        expect(outside, 0, reason: '${p.id}: ink on the mat');
      }
    });

    test('the seam between the faces is paper', () async {
      final (bytes, w, h) = await bake(GalleryProjects.all.first);
      final x = (layout.piece.right + PieceCard.seam / 2).round();
      for (var y = 0; y < h; y += 7) {
        expect(isPaper(bytes, w, x, y), isTrue, reason: 'row $y');
      }
    });

    test('the label is set: ink on its paper', () async {
      final (bytes, w, _) = await bake(GalleryProjects.all.first);
      var ink = 0;
      final l = layout.label;
      for (var y = l.top.round(); y < l.bottom.round(); y += 3) {
        for (var x = l.left.round(); x < l.right.round(); x += 3) {
          final i = (y * w + x) * 4;
          if (bytes.getUint8(i) < 90) ink++;
        }
      }
      expect(ink, greaterThan(50));
    });
  });

  test('a piece in preparation is drawn dimmer', () async {
    Future<int> darkest(Project p) async {
      final image = await PieceCard.render(project: p);
      final bytes = (await image.toByteData())!;
      var min = 255;
      for (var y = 0; y < layout.piece.height.round(); y += 2) {
        for (var x = 0; x < layout.piece.width.round(); x += 2) {
          final v = bytes.getUint8((y * image.width + x) * 4);
          if (v < min) min = v;
        }
      }
      image.dispose();
      return min;
    }

    final live = GalleryProjects.all.firstWhere((p) => p.isLive);
    final soon = GalleryProjects.all.firstWhere((p) => !p.isLive);
    expect(await darkest(soon), greaterThan(await darkest(live) + 60));
  });
}
