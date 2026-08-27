import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/gallery_dimensions.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';
import 'package:portfolio/domain/gallery/project_data.dart';

void main() {
  final layout = GalleryLayout.build();

  Iterable<Placement> of(SurfaceKind kind) =>
      layout.where((p) => p.kind == kind);

  group('the room', () {
    test('is enclosed', () {
      expect(of(SurfaceKind.floor), hasLength(1));
      expect(of(SurfaceKind.ceiling), hasLength(1));
      expect(of(SurfaceKind.sideWall), hasLength(2));
      expect(of(SurfaceKind.backWall), hasLength(1));
    });

    test('the ceiling is above the floor', () {
      expect(
        of(SurfaceKind.ceiling).single.position.y,
        greaterThan(of(SurfaceKind.floor).single.position.y),
      );
    });

    test('the walls face each other across the corridor', () {
      final xs = of(SurfaceKind.sideWall).map((p) => p.position.x).toList()
        ..sort();

      expect(xs.first, -GalleryDimensions.wallX);
      expect(xs.last, GalleryDimensions.wallX);
    });

    test('the ground extends past the walls, so no edge is visible', () {
      expect(
        of(SurfaceKind.floor).single.extents.x,
        greaterThan(GalleryDimensions.corridorWidth * 4),
      );
    });

    test('the left wall runs the length of the corridor', () {
      // Only the left. This test used to assert both, which is what walled
      // the testimonial wing off — see the corner group below.
      final left = of(SurfaceKind.sideWall).firstWhere((w) => w.position.x < 0);
      expect(left.extents.z, greaterThan(GalleryDimensions.corridorLength));
    });

    test('every wall is tall enough to meet the ceiling', () {
      final span = GalleryDimensions.ceilY - GalleryDimensions.floorY;
      for (final wall in <Placement>[
        ...of(SurfaceKind.sideWall),
        of(SurfaceKind.backWall).single,
        of(SurfaceKind.wingWall).single,
      ]) {
        expect(
          wall.extents.y,
          greaterThanOrEqualTo(span),
          reason: 'a short wall leaves a strip of void above it',
        );
      }
    });
  });

  group('the work', () {
    test('every project is hung, and only once', () {
      final frames = of(SurfaceKind.frame).toList();
      final shown = frames.map((f) => f.project!.id).toSet();

      expect(frames, hasLength(GalleryProjects.all.length));
      expect(shown, hasLength(GalleryProjects.all.length));
    });

    test('frames face across the corridor, not along it', () {
      // A frame left unrotated lies flat against the wall it hangs on, edge-on
      // to the visitor and effectively invisible — and nothing in a running
      // scene says so.
      for (final frame in of(SurfaceKind.frame)) {
        expect(frame.rotationY.abs(), closeTo(GalleryLayout.quarterTurn, 1e-9));
      }
    });

    test('the two walls face opposite ways', () {
      final rotations =
          of(SurfaceKind.frame).map((f) => f.rotationY).toSet();
      expect(rotations, hasLength(2));
      expect(rotations.reduce((a, b) => a + b), closeTo(0, 1e-9));
    });

    test('frames hang inside the corridor, just off the wall', () {
      for (final frame in of(SurfaceKind.frame)) {
        expect(frame.position.x.abs(), lessThan(GalleryDimensions.wallX));
        expect(
          frame.position.x.abs(),
          greaterThan(GalleryDimensions.wallX - 0.5),
          reason: 'should be against the wall, not floating mid-corridor',
        );
      }
    });

    test('no frame is behind the visitor at the start', () {
      // Anything at or past the entrance is already behind the camera when
      // the walk begins.
      for (final frame in of(SurfaceKind.frame)) {
        expect(frame.position.z, lessThan(0));
      }
    });

    test('no frame is buried in the back wall', () {
      for (final frame in of(SurfaceKind.frame)) {
        expect(frame.position.z, greaterThan(GalleryDimensions.backWallZ + 1));
      }
    });

    test('frames are evenly spaced down each wall', () {
      final left = of(SurfaceKind.frame)
          .where((f) => f.position.x < 0)
          .map((f) => f.position.z)
          .toList()
        ..sort();

      for (var i = 1; i < left.length; i++) {
        expect(
          left[i - 1] - left[i],
          closeTo(-GalleryDimensions.spacing, 1e-9),
        );
      }
    });

    test('frames clear the floor and the ceiling', () {
      final floorY = GalleryDimensions.floorY;
      final ceilY = GalleryDimensions.ceilY;

      for (final frame in of(SurfaceKind.frame)) {
        final half = frame.extents.y / 2;
        expect(frame.position.y - half, greaterThan(floorY));
        expect(frame.position.y + half, lessThan(ceilY));
      }
    });
  });

  group('the corner into the testimonial wing', () {
    test('the right wall stops short, opening the L', () {
      // This is the corner the camera turns. A right wall run to full length
      // walls the wing off and the camera pans straight through it, which
      // reads as the room turning inside out rather than as a corner.
      final walls = of(SurfaceKind.sideWall).toList();
      final right = walls.firstWhere((w) => w.position.x > 0);
      final left = walls.firstWhere((w) => w.position.x < 0);

      expect(right.extents.z, lessThan(left.extents.z));
      expect(right.extents.z, GalleryDimensions.rightWallLength);
    });

    test('the opening reaches the wing', () {
      // The gap between where the right wall ends and the back wall must be
      // wide enough to walk the camera through.
      final right = of(SurfaceKind.sideWall)
          .firstWhere((w) => w.position.x > 0);
      final wallEndsAt = right.position.z - right.extents.z / 2;

      expect(wallEndsAt, greaterThan(GalleryDimensions.backWallZ));
      expect(
        wallEndsAt - GalleryDimensions.backWallZ,
        greaterThan(GalleryDimensions.corridorWidth / 2),
        reason: 'too narrow an opening reads as a slot, not a room',
      );
    });

    test('the far wall spans the wing the camera pans into', () {
      // Centred on the corridor it would run out before the last card.
      final back = of(SurfaceKind.backWall).single;
      final rightEdge = back.position.x + back.extents.x / 2;

      expect(rightEdge, greaterThan(GalleryDimensions.testPanEndX));
    });

    test('the far wall does not run off into empty space on the left', () {
      final back = of(SurfaceKind.backWall).single;
      final leftEdge = back.position.x - back.extents.x / 2;

      expect(leftEdge, closeTo(-GalleryDimensions.corridorWidth, 0.01));
    });

    test('the wing is closed behind the visitor', () {
      // Without it the visitor reads the testimonials with the void at their
      // back, and the room stops being a room.
      final wing = of(SurfaceKind.wingWall).single;

      expect(wing.position.z, greaterThan(GalleryDimensions.backWallZ));
      expect(wing.position.x, greaterThan(GalleryDimensions.wallX));
    });
  });
}
