import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/gallery_dimensions.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';
import 'package:portfolio/domain/gallery/gallery_lighting.dart';
import 'package:portfolio/domain/gallery/project_data.dart';

void main() {
  final lights = GalleryLighting.build();
  final spots = lights.where((l) => l.kind == LightKind.spot).toList();

  /// The corridor runs between the side walls; the testimonial wing is the
  /// bay off it, past where the right wall stops. Several of these rules are
  /// about the corridor specifically and were written when it was the only
  /// place with lights in it.
  bool inCorridor(LightPlacement l) =>
      l.position.x.abs() < GalleryDimensions.wallX;

  final corridorSpots = spots.where(inCorridor).toList();
  final wingSpots = spots.where((l) => !inCorridor(l)).toList();
  final frames = GalleryLayout.build()
      .where((p) => p.kind == SurfaceKind.frame)
      .toList();

  group('the work is lit', () {
    test('every piece has its own light', () {
      // A museum corridor is a dim room with the work picked out of it. One
      // light for the whole corridor would flatten it into a lobby.
      final backWall = 1;
      expect(
        corridorSpots,
        hasLength(GalleryProjects.all.length + backWall),
      );
    });

    test('so does every frame on the far wall', () {
      // The wall wash reaches the plaster but not the work on it, and a thing
      // nobody lights is a thing nobody sees.
      expect(wingSpots, hasLength(GalleryDimensions.testimonialCount));
    });

    test('lights hang above the work, not level with it', () {
      for (final spot in spots) {
        expect(spot.position.y, greaterThan(GalleryDimensions.frameY));
      }
    });

    test('lights sit inside the room, not behind the walls', () {
      // A light on the far side of the wall it is meant to illuminate lights
      // nothing at all, and there is no error to say so.
      for (final light in lights) {
        expect(light.position.y, lessThan(GalleryDimensions.ceilY));
        expect(light.position.z, greaterThan(GalleryDimensions.backWallZ));
      }

      // Bounded per room rather than globally: the corridor's lights belong
      // between its walls, and the wing's belong along the stretch of far
      // wall the visitor pans across. One rule for both would have to be the
      // looser of the two, and would stop catching anything.
      for (final light in lights.where(inCorridor)) {
        expect(
          light.position.x.abs(),
          lessThan(GalleryDimensions.wallX),
          reason: 'a light outside the corridor illuminates nothing',
        );
      }
      for (final light in wingSpots) {
        expect(light.position.x, greaterThanOrEqualTo(
          GalleryDimensions.testStartX,
        ));
        expect(
          light.position.x,
          lessThanOrEqualTo(GalleryDimensions.testPanEndX),
          reason: 'a light past the last frame lights bare wall',
        );
      }
    });

    test('each frame light stands off its own wall, aiming back at it', () {
      for (final frame in frames) {
        final onLeft = frame.position.x < 0;
        final nearest = spots
            .where((s) => (s.position.z - frame.position.z).abs() < 0.01)
            .where((s) => (s.position.x < 0) == onLeft)
            .toList();

        expect(nearest, hasLength(1), reason: 'at z=${frame.position.z}');

        final light = nearest.single;
        // Standing off the wall and aiming back is what rakes the work.
        // Aimed straight down it would light the floor in front of it.
        expect(light.position.x.abs(), lessThan(frame.position.x.abs()));
        expect(light.direction!.x.sign, onLeft ? -1 : 1);
        expect(light.direction!.y, lessThan(0), reason: 'must aim downward');
      }
    });

    test('aims are unit length', () {
      // A direction that is not normalised skews the cone in ways the cone
      // angles no longer describe.
      for (final spot in spots) {
        expect(spot.direction!.length, closeTo(1, 1e-6));
      }
    });

    test('cones open outward from their bright centre', () {
      for (final spot in spots) {
        expect(spot.innerCone, lessThan(spot.outerCone));
        expect(spot.innerCone, greaterThanOrEqualTo(0));
        expect(spot.outerCone, lessThan(1.5707963267948966));
      }
    });
  });

  group('the room between the work', () {
    test('has fill, so the gaps read as shadow rather than as nothing', () {
      expect(lights.where((l) => l.kind == LightKind.point), isNotEmpty);
    });

    test('fill runs the length of the corridor', () {
      final fill = lights.where((l) => l.kind == LightKind.point).toList();
      final deepest = fill.map((l) => l.position.z).reduce(
        (a, b) => a < b ? a : b,
      );

      expect(deepest, lessThan(GalleryDimensions.backWallZ / 2));
    });

    test('fill hangs from the ceiling, down the centre line', () {
      for (final light in lights.where((l) => l.kind == LightKind.point)) {
        expect(light.position.x, 0);
        expect(light.position.y, greaterThan(GalleryDimensions.frameY));
      }
    });

    test('every light reaches something', () {
      // A range of zero means unbounded, which is fine; a small positive
      // range that does not span the corridor is a light nobody sees.
      for (final light in lights) {
        if (light.range == 0) continue;
        expect(light.range, greaterThan(GalleryDimensions.corridorWidth / 2));
      }
    });
  });
}
