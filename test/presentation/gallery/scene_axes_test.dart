import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/gallery_camera_path.dart';
import 'package:portfolio/domain/gallery/gallery_dimensions.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';
import 'package:portfolio/presentation/gallery/scene_axes.dart';
import 'package:vector_math/vector_math.dart';

void main() {
  group('SceneAxes', () {
    test('mirrors sideways and leaves the rest alone', () {
      final converted = SceneAxes.position(Vector3(3, 4, 5));

      expect(converted.x, -3);
      expect(converted.y, 4, reason: 'up is up in both');
      expect(converted.z, 5, reason: 'depth is depth in both');
    });

    test('is its own inverse', () {
      // A pure mirror, not an arbitrary transform. If this stops holding, the
      // conversion has grown into something that cannot safely be applied at
      // a single boundary.
      final original = Vector3(1.5, -2, 7);
      final round = SceneAxes.position(SceneAxes.position(original));

      expect(round.x, original.x);
      expect(round.y, original.y);
      expect(round.z, original.z);
    });

    test('turns rotations the other way', () {
      // Mirroring an axis reverses the handedness of rotations about the
      // axes perpendicular to it.
      expect(SceneAxes.rotationY(GalleryLayout.quarterTurn),
          -GalleryLayout.quarterTurn);
      expect(SceneAxes.rotationY(0), 0);
    });
  });

  group('the room survives the crossing', () {
    test('the walls stay on opposite sides of the corridor', () {
      final left = SceneAxes.position(Vector3(-GalleryDimensions.wallX, 0, 0));
      final right = SceneAxes.position(Vector3(GalleryDimensions.wallX, 0, 0));

      expect(left.x.sign, isNot(right.x.sign));
      expect(left.x.abs(), right.x.abs());
    });

    test('the camera still pans toward the testimonials', () {
      // The failure mode this exists for: converting the room but not the
      // camera, or the other way round. The visitor then walks away from the
      // wall the work is hanging on, and nothing reports a problem.
      final wall = SceneAxes.position(
        Vector3(GalleryDimensions.testStartX, 0, 0),
      );
      final panEnd = SceneAxes.position(
        GalleryCameraPath.poseAt(1).position,
      );

      expect(wall.x.sign, panEnd.x.sign);
      expect(panEnd.x.abs(), greaterThan(0));
    });

    test('each frame still hangs against a wall, not in mid-air', () {
      for (final piece in GalleryLayout.build()) {
        if (piece.kind != SurfaceKind.frame) continue;

        final converted = SceneAxes.position(piece.position);
        expect(
          converted.x.abs(),
          closeTo(piece.position.x.abs(), 1e-9),
          reason: 'mirroring must not move a frame off its wall',
        );
      }
    });

    test('the walk stays centred after crossing', () {
      // The corridor is symmetrical about its centre line, so the walk should
      // be unaffected by the mirror — if it is not, the conversion is doing
      // more than mirroring.
      for (var p = 0.0; p < GalleryCameraPath.walkFraction; p += 0.05) {
        final converted = SceneAxes.position(
          GalleryCameraPath.poseAt(p).position,
        );
        expect(converted.x, 0, reason: 'at $p');
      }
    });
  });
}
