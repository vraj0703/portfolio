import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/gallery_camera_path.dart';
import 'package:portfolio/domain/gallery/gallery_dimensions.dart';

void main() {
  group('the walk', () {
    test('starts just inside the entrance, looking down the corridor', () {
      final pose = GalleryCameraPath.poseAt(0);

      expect(pose.position.z, GalleryCameraPath.startZ);
      expect(pose.position.x, 0, reason: 'centred in the corridor');
      expect(pose.target.z, lessThan(pose.position.z), reason: 'looking in');
    });

    test('advances into the corridor', () {
      final early = GalleryCameraPath.poseAt(0.1);
      final late_ = GalleryCameraPath.poseAt(0.5);

      expect(late_.position.z, lessThan(early.position.z));
    });

    test('stops short of the back wall rather than at it', () {
      // Walking into the wall would put the testimonials past the near plane.
      // Sampled just inside the end of the walk. The epsilon is a fraction
      // of the walk rather than of the whole scroll, so shortening the walk
      // to make room for the hall does not turn it into a bigger step.
      final arrival = GalleryCameraPath.poseAt(
        GalleryCameraPath.walkFraction * 0.999,
      );

      expect(arrival.position.z, greaterThan(GalleryDimensions.backWallZ));
      expect(
        arrival.position.z,
        closeTo(GalleryDimensions.wallLockZ, 0.05),
      );
    });

    test('stays centred throughout', () {
      for (var p = 0.0; p < GalleryCameraPath.walkFraction; p += 0.02) {
        expect(GalleryCameraPath.poseAt(p).position.x, 0, reason: 'at $p');
      }
    });

    test('attention turns to the back wall only as it approaches', () {
      // Squared, so the swing is imperceptible until the wall is genuinely
      // close — otherwise the whole walk is spent staring past the frames.
      final early = GalleryCameraPath.poseAt(0.2);
      final arriving = GalleryCameraPath.poseAt(0.55);

      final earlyGap = (early.target.z - GalleryDimensions.backWallZ).abs();
      final arrivingGap =
          (arriving.target.z - GalleryDimensions.backWallZ).abs();

      expect(arrivingGap, lessThan(earlyGap));
    });
  });

  group('the pan', () {
    test('begins where the walk ended', () {
      final pose = GalleryCameraPath.poseAt(GalleryCameraPath.walkFraction);
      expect(pose.position.x, closeTo(0, 0.01));
    });

    test('tracks sideways to the last card', () {
      // The pan ends at `panEnd`, not at 1: the route carries on into the
      // hall from there.
      final pose = GalleryCameraPath.poseAt(GalleryCameraPath.panEnd);
      expect(pose.position.x, closeTo(GalleryCameraPath.panEndX, 0.01));
    });

    test('views the wall square-on the whole way', () {
      // Letting the target lag behind the position would skew every card as
      // it passed.
      for (var p = GalleryCameraPath.walkFraction;
          p < GalleryCameraPath.panEnd;
          p += 0.02) {
        final pose = GalleryCameraPath.poseAt(p);
        expect(pose.target.x, closeTo(pose.position.x, 1e-9), reason: 'at $p');
      }
    });

    test('holds its distance from the wall', () {
      for (var p = GalleryCameraPath.walkFraction;
          p < GalleryCameraPath.panEnd;
          p += 0.05) {
        expect(
          GalleryCameraPath.poseAt(p).position.z,
          closeTo(GalleryDimensions.wallLockZ, 1e-9),
        );
      }
    });
  });

  group('the handover', () {
    test('does not jump between the two movements', () {
      // The one place a two-part path visibly breaks. A discontinuity here
      // reads as the camera being teleported mid-walk.
      // Sampled tightly. A fixed slice of *progress* is a different physical
      // step depending on how long the movement either side of it is, so a
      // loose epsilon here measures the sampling rather than the path.
      const seam = GalleryCameraPath.walkFraction;
      final before = GalleryCameraPath.poseAt(seam - 1e-5);
      final after = GalleryCameraPath.poseAt(seam + 1e-5);

      expect((after.position - before.position).length, lessThan(0.01));
    });

    test('the eye height shifts only slightly across the seam', () {
      const seam = GalleryCameraPath.walkFraction;
      final before = GalleryCameraPath.poseAt(seam - 0.0005);
      final after = GalleryCameraPath.poseAt(seam + 0.0005);

      expect((after.position.y - before.position.y).abs(), lessThan(0.2));
    });
  });

  group('the whole route', () {
    test('never leaves the room', () {
      for (var p = 0.0; p <= 1; p += 0.01) {
        final pose = GalleryCameraPath.poseAt(p);

        // The route now reaches past the wing into the hall, so the far
        // bound is the hall's end wall rather than the last testimonial.
        expect(
          pose.position.x,
          inInclusiveRange(
            -1,
            GalleryDimensions.kbX + GalleryDimensions.kbDepth / 2,
          ),
        );
        expect(pose.position.z, greaterThan(GalleryDimensions.backWallZ));
        expect(pose.position.z, lessThanOrEqualTo(GalleryCameraPath.startZ));
      }
    });

    test('always looks somewhere other than where it stands', () {
      // A zero-length view vector makes the look-at matrix degenerate, which
      // blanks the frame rather than throwing.
      for (var p = 0.0; p <= 1; p += 0.01) {
        final pose = GalleryCameraPath.poseAt(p);
        expect((pose.target - pose.position).length, greaterThan(0.1),
            reason: 'at $p');
      }
    });

    test('clamps rather than running past either end', () {
      expect(
        GalleryCameraPath.poseAt(-1).position.z,
        GalleryCameraPath.poseAt(0).position.z,
      );
      expect(
        GalleryCameraPath.poseAt(2).position.x,
        GalleryCameraPath.poseAt(1).position.x,
      );
    });
  });

  group('arriving from the previous stage', () {
    test('the walk starts at the entrance, not partway in', () {
      // Whatever the gate lets through, the corridor itself always begins at
      // the door. See ScrollGate for how the previous gesture is kept out.
      expect(GalleryCameraPath.poseAt(0).position.z, GalleryCameraPath.startZ);
    });
  });
}
