import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/gallery_depth.dart';
import 'package:portfolio/domain/gallery/gallery_dimensions.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';
import 'package:portfolio/domain/gallery/project_focus.dart';

/// The pieces as hung: portrait, with their labels in the gutter beside
/// them, and a focus that frames the two together. Positions are 32-bit
/// (`Vector3`), so equalities hold to 1e-5, not to the last digit.
void main() {
  final pieces = GalleryLayout.build()
      .where((p) => p.kind == SurfaceKind.frame)
      .toList();

  test('a piece is portrait, 4:5, at the frames\' full height', () {
    expect(
      GalleryLayout.pieceWidth / GalleryDimensions.frameMaxHeight,
      closeTo(0.8, 1e-12),
    );
    for (final piece in pieces) {
      expect(piece.extents.x, closeTo(GalleryLayout.pieceWidth, 1e-5));
      expect(piece.extents.y, closeTo(GalleryDimensions.frameMaxHeight, 1e-5));
    }
  });

  test('the far wall keeps its landscape frames', () {
    final far = GalleryLayout.build()
        .where((p) => p.kind == SurfaceKind.testimonialFrame);
    for (final frame in far) {
      expect(frame.extents.x, GalleryLayout.frameWidth);
    }
  });

  group('the label', () {
    test('hangs in the gutter: clear of its piece and of the next', () {
      for (final piece in pieces) {
        final label = GalleryLayout.labelCentreFor(piece);
        // Along the wall, measured from the piece's centre.
        final along = (label.z - piece.position.z).abs();
        final near = along - GalleryLayout.labelWidth / 2;
        final far = along + GalleryLayout.labelWidth / 2;
        expect(near, greaterThan(GalleryLayout.pieceWidth / 2),
            reason: '${piece.project?.id}: overlaps its piece');
        expect(
          far,
          lessThan(GalleryDimensions.spacing - GalleryLayout.pieceWidth / 2),
          reason: '${piece.project?.id}: reaches the next piece',
        );
      }
    });

    test('hangs on the same wall, painted on the plaster', () {
      for (final piece in pieces) {
        final label = GalleryLayout.labelCentreFor(piece);
        final wall = piece.position.x.isNegative
            ? -GalleryDimensions.wallX
            : GalleryDimensions.wallX;
        final off = (label.x - wall).abs() - GalleryLayout.labelDepth / 2;
        // Clear of the slab (half its thickness), and not standing off it.
        expect(off, closeTo(GalleryLayout.paintedOnWall, 1e-5));
      }
    });

    test('stays inside the room: not past the back wall or the entrance', () {
      for (final piece in pieces) {
        final z = GalleryLayout.labelCentreFor(piece).z;
        expect(z - GalleryLayout.labelWidth / 2, greaterThan(GalleryDimensions.backWallZ));
        expect(z + GalleryLayout.labelWidth / 2, lessThan(0));
      }
    });

    test('its foot sits just above the piece\'s, its head below the top', () {
      for (final piece in pieces) {
        final y = GalleryLayout.labelCentreFor(piece).y;
        final foot = y - GalleryLayout.labelHeight / 2;
        final pieceFoot = piece.position.y - piece.extents.y / 2;
        expect(foot, closeTo(pieceFoot + GalleryLayout.labelLift, 1e-5));
        expect(
          y + GalleryLayout.labelHeight / 2,
          lessThan(piece.position.y + piece.extents.y / 2),
        );
      }
    });

    test('hangs on the same side of every piece, as the visitor sees it', () {
      // The piece's own across axis turns with it, so one side in its own
      // terms is one side to a visitor facing it, on either wall.
      for (final piece in pieces) {
        final label = GalleryLayout.labelCentreFor(piece);
        final across = GalleryLayout.acrossOf(piece);
        final towardLabel = (label - piece.position)..x = 0;
        expect(towardLabel.dot(across) * GalleryLayout.labelSide, greaterThan(0));
      }
    });
  });

  group('the focus frames the piece and its label together', () {
    const aspects = <double>[16 / 10, 390 / 844, 360 / 800, 21 / 9];

    test('the camera stays in the corridor, on a phone too', () {
      for (final aspect in aspects) {
        for (final piece in pieces) {
          final pose = ProjectFocus.poseFor(piece, aspect: aspect);
          expect(ProjectFocus.fitsInside(pose), isTrue,
              reason: '${piece.project?.id} at $aspect');
        }
      }
    });

    test('it aims between the piece and its label, not at the piece', () {
      for (final piece in pieces) {
        final pose = ProjectFocus.poseFor(piece, aspect: 16 / 10);
        final label = GalleryLayout.labelCentreFor(piece);
        final toPiece = (piece.position.z - pose.target.z).abs();
        final toLabel = (label.z - pose.target.z).abs();
        expect(toPiece, greaterThan(0));
        // The composition's far edges sit equally either side of the aim.
        final pieceEdge = toPiece + GalleryLayout.pieceWidth / 2;
        final labelEdge = toLabel + GalleryLayout.labelWidth / 2;
        expect(pieceEdge, closeTo(labelEdge, 1e-5));
      }
    });

    test('on a wide screen the whole composition is in the shot', () {
      for (final aspect in aspects.where((a) => a >= 1)) {
        final piece = pieces.first;
        final pose = ProjectFocus.poseFor(piece, aspect: aspect);
        final distance = (pose.position.x - pose.target.x).abs();
        final needed = ProjectFocus.distanceFor(
          width: ProjectFocus.compositionWidth,
          height: 0,
          aspect: aspect,
          room: 1,
        );
        expect(distance, greaterThanOrEqualTo(needed), reason: '$aspect');
      }
    });

    test('on a portrait screen the piece alone is framed, larger', () {
      // The label's words are drawn over the screen there instead.
      for (final aspect in aspects.where((a) => a < 1)) {
        for (final piece in pieces) {
          final alone = ProjectFocus.poseFor(piece, aspect: aspect);
          expect(alone.target.z, closeTo(piece.position.z, 1e-5));
          final distance = (alone.position.x - alone.target.x).abs();
          final composition = ProjectFocus.distanceFor(
            width: ProjectFocus.compositionWidth,
            height: 0,
            aspect: aspect,
            room: ProjectFocus.portraitMargin,
          );
          expect(distance, lessThan(composition), reason: '$aspect');
          // And still the whole piece, side to side.
          final needed = ProjectFocus.distanceFor(
            width: GalleryLayout.pieceWidth,
            height: 0,
            aspect: aspect,
            room: 1,
          );
          expect(distance, greaterThanOrEqualTo(needed));
        }
      }
    });
  });

  group('on a portrait screen', () {
    // Where a point on the wall lands on screen, as a share of the height
    // from the top, for a camera looking square on at [pose].
    double fromTop(FocusPose pose, double y) {
      final d = (pose.position.x - pose.target.x).abs();
      final half = d * math.tan(GalleryDimensions.fovRadians / 2);
      return (pose.target.y + half - y) / (2 * half);
    }

    test('the piece is centred in the space above the drawn controls', () {
      for (final reserve in <double>[0.1, 0.14, 0.2]) {
        for (final piece in pieces) {
          final pose = ProjectFocus.poseFor(
            piece,
            aspect: 390 / 844,
            reserveBelow: reserve,
          );
          expect(
            fromTop(pose, piece.position.y),
            closeTo((1 - reserve) / 2, 1e-4),
            reason: '${piece.project?.id} at $reserve',
          );
          // Square on: the camera looks level, at its own height.
          expect(pose.position.y, closeTo(pose.target.y, 1e-6));
        }
      }
    });

    test('the whole piece is in the space above them, top and bottom', () {
      // The row and the label's words: 330 px, on a tall phone and a short
      // one, where the height rather than the width decides.
      for (final (w, h) in <(double, double)>[(390, 844), (360, 640)]) {
        final reserve = 330 / h;
        final piece = pieces.first;
        final pose = ProjectFocus.poseFor(
          piece,
          aspect: w / h,
          reserveBelow: reserve,
        );
        final top = fromTop(pose, piece.position.y + piece.extents.y / 2);
        final foot = fromTop(pose, piece.position.y - piece.extents.y / 2);
        expect(top, greaterThan(0), reason: '${w}x$h');
        expect(foot, lessThan(1 - reserve), reason: '${w}x$h');
      }
    });

    test('the piece keeps clear of a band at the top as well', () {
      // The site's mark parks in the top corner; on a phone it sat on the
      // piece's paper.
      for (final (w, h) in <(double, double)>[(390, 844), (360, 640)]) {
        final below = 330 / h, above = 90 / h;
        final piece = pieces.first;
        final pose = ProjectFocus.poseFor(
          piece,
          aspect: w / h,
          reserveBelow: below,
          reserveAbove: above,
        );
        final top = fromTop(pose, piece.position.y + piece.extents.y / 2);
        final foot = fromTop(pose, piece.position.y - piece.extents.y / 2);
        expect(top, greaterThanOrEqualTo(above - 1e-6), reason: '${w}x$h');
        expect(foot, lessThanOrEqualTo(1 - below + 1e-6), reason: '${w}x$h');
        // Centred between the two bands.
        expect(
          fromTop(pose, piece.position.y),
          closeTo(above + (1 - above - below) / 2, 1e-4),
        );
      }
    });

    test('a wide screen is not moved by it', () {
      final piece = pieces.first;
      final a = ProjectFocus.poseFor(piece, aspect: 16 / 10);
      final b = ProjectFocus.poseFor(piece, aspect: 16 / 10, reserveBelow: 0.2);
      expect(b.target.y, a.target.y);
    });
  });

  group('Escape steps back one level at a time', () {
    test('the sheet, then the piece, then nothing', () {
      expect(GalleryDepth.reading.back, GalleryDepth.focused);
      expect(GalleryDepth.focused.back, GalleryDepth.corridor);
      expect(GalleryDepth.corridor.back, isNull);
    });

    test('the depth is read from what the view holds', () {
      expect(GalleryDepth.of(focused: false, reading: false), GalleryDepth.corridor);
      expect(GalleryDepth.of(focused: true, reading: false), GalleryDepth.focused);
      expect(GalleryDepth.of(focused: true, reading: true), GalleryDepth.reading);
      // No sheet without a piece: a stale flag cannot open one over the
      // corridor.
      expect(GalleryDepth.of(focused: false, reading: true), GalleryDepth.corridor);
    });
  });
}
