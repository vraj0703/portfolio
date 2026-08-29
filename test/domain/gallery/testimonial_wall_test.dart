import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/gallery_dimensions.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';
import 'package:portfolio/domain/gallery/walk_order.dart';

void main() {
  final pieces = GalleryLayout.build();
  final wall = pieces
      .where((p) => p.kind == SurfaceKind.testimonialFrame)
      .toList();

  test('five frames hang on the far wall', () {
    expect(wall, hasLength(5));
    expect(wall, hasLength(GalleryDimensions.testimonialCount));
  });

  test('they stand clear of the wall, not inside it', () {
    // The far wall is a slab centred on its plane, so anything nudged a few
    // millimetres toward the room is still buried in it — the bug that hid
    // the wall lettering completely.
    final back = pieces.firstWhere((p) => p.kind == SurfaceKind.backWall);
    final face = back.position.z + back.extents.z / 2;

    for (final frame in wall) {
      expect(frame.position.z - frame.extents.z / 2, greaterThan(face));
    }
  });

  test('they face down the corridor, unturned', () {
    // The far wall already faces the visitor. A quarter turn — right for the
    // corridor's frames — would stand these edge-on to the only place they
    // are ever seen from.
    for (final frame in wall) {
      expect(frame.rotationY, 0);
    }
  });

  test('they are evenly spaced and none runs past the wall', () {
    final xs = wall.map((f) => f.position.x).toList();
    for (var i = 1; i < xs.length; i++) {
      expect(xs[i] - xs[i - 1], GalleryDimensions.testSpacing);
    }

    final back = pieces.firstWhere((p) => p.kind == SurfaceKind.backWall);
    final rightEdge = back.position.x + back.extents.x / 2;
    expect(
      xs.last + GalleryLayout.frameWidth / 2,
      lessThan(rightEdge),
      reason: 'the last frame hangs off the end of the wall',
    );
  });

  test('the camera pan ends on the last frame, not past it', () {
    // The pan's end is derived from the same count, so a wall of five cannot
    // leave the camera drifting on toward a sixth that is not there.
    expect(GalleryDimensions.testPanEndX, wall.last.position.x);
  });

  test('they stay out of the corridor stepping order', () {
    // A visitor pressing "next work" must not be sent to the far wall.
    final order = WalkOrder(pieces);

    expect(order.frames.every((f) => f.kind == SurfaceKind.frame), isTrue);
    expect(order.frames, hasLength(7));
  });

  test('they clear the floor and the ceiling', () {
    for (final frame in wall) {
      final half = frame.extents.y / 2;
      expect(frame.position.y - half, greaterThan(GalleryDimensions.floorY));
      expect(frame.position.y + half, lessThan(GalleryDimensions.ceilY));
    }
  });
}
