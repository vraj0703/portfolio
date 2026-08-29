import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/gallery_camera_path.dart';
import 'package:portfolio/domain/gallery/gallery_dimensions.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';
import 'package:portfolio/domain/gallery/keyboard_layout.dart';

void main() {


  test('the pan ends on the hall centre line', () {
    // What lets the visitor scroll straight into the hall instead of being
    // flown there by a button. If these ever diverge the route needs a
    // dogleg, and this is the test that will say so.
    expect(GalleryDimensions.wallLockZ, GalleryDimensions.kbZ);
  });

  test('the three movements share the whole scroll', () {
    expect(
      GalleryCameraPath.walkFraction +
          GalleryCameraPath.panFraction +
          GalleryCameraPath.hallFraction,
      closeTo(1, 1e-9),
    );
  });

  group('the seam into the hall', () {
    test('position does not jump', () {
      // A two-part path breaks visibly at its handover and nowhere else.
      final before = GalleryCameraPath.poseAt(GalleryCameraPath.panEnd - 1e-6);
      final after = GalleryCameraPath.poseAt(GalleryCameraPath.panEnd);

      expect(before.position.x, closeTo(after.position.x, 1e-3));
      expect(before.position.y, closeTo(after.position.y, 1e-3));
      expect(before.position.z, closeTo(after.position.z, 1e-3));
    });

    test('the look does not jump', () {
      final before = GalleryCameraPath.poseAt(GalleryCameraPath.panEnd - 1e-6);
      final after = GalleryCameraPath.poseAt(GalleryCameraPath.panEnd);

      expect(before.target.x, closeTo(after.target.x, 1e-3));
      expect(before.target.z, closeTo(after.target.z, 1e-3));
    });
  });

  group('the approach', () {
    test('runs forward the whole way, never backing up', () {
      var previous = double.negativeInfinity;
      for (var p = GalleryCameraPath.panEnd; p <= 1.0; p += 0.005) {
        final x = GalleryCameraPath.poseAt(p).position.x;
        expect(x, greaterThanOrEqualTo(previous - 1e-6), reason: 'at $p');
        previous = x;
      }
    });

    test('passes through the doorway, not through a wall', () {
      // The entry side is two wall segments with a gap between them. The
      // camera runs at a fixed depth, so it either threads the gap or it
      // travels through plaster.
      final entry = GalleryLayout.build().where(
        (w) =>
            w.kind == SurfaceKind.hallWall &&
            w.position.x == GalleryDimensions.kbEntryX,
      );

      for (final segment in entry) {
        final near = segment.position.z - segment.extents.z / 2;
        final far = segment.position.z + segment.extents.z / 2;
        expect(
          GalleryDimensions.wallLockZ > near &&
              GalleryDimensions.wallLockZ < far,
          isFalse,
          reason: 'the route runs through an entry wall segment',
        );
      }
    });

    test('ends short of the board, looking at it', () {
      final end = GalleryCameraPath.poseAt(1);
      final board = KeyboardLayout.anchor;

      expect(end.position.x, lessThan(board.x));
      expect(board.x - end.position.x, closeTo(GalleryCameraPath.hallViewDistance, 1e-6));

      // Looking at the board itself, not past it.
      expect(end.target.x, closeTo(board.x, 1e-3));
      expect(end.target.z, closeTo(board.z, 1e-3));

      // And slightly down onto it, the way anyone looks at a keyboard.
      expect(end.position.y, greaterThan(end.target.y));
    });

    test('stays inside the hall once through the door', () {
      final half = GalleryDimensions.kbDepth / 2;
      final end = GalleryCameraPath.poseAt(1);

      expect(end.position.x, greaterThan(GalleryDimensions.kbEntryX));
      expect(end.position.x, lessThan(GalleryDimensions.kbX + half));
    });

    test('leaves the wall behind gradually, not the instant it sets off', () {
      // The turn used to wait until the visitor had crossed the threshold.
      // It now runs as they cover the last of the wing, so that by the time
      // they are at the doorway they are facing into the hall and can watch
      // the board rise. What must not happen is a spin the moment the pan
      // ends, beside the last testimonial they were reading.
      final justSetOff = GalleryCameraPath.poseAt(
        GalleryCameraPath.panEnd +
            GalleryCameraPath.hallFraction * 0.05,
      );

      expect(
        justSetOff.target.z,
        closeTo(GalleryDimensions.backWallZ, 0.6),
        reason: 'spun away from the wall as soon as the pan ended',
      );
    });

    test('is facing the hall by the time it reaches the doorway', () {
      // Everything the reveal depends on. Facing the wall here would put the
      // board's entrance behind the visitor's shoulder.
      final atDoor = GalleryCameraPath.poseAt(
        GalleryCameraPath.panEnd +
            GalleryCameraPath.hallFraction * GalleryCameraPath.doorwayShare,
      );

      expect(
        atDoor.target.x,
        closeTo(KeyboardLayout.anchor.x, 1e-6),
        reason: 'still looking along the wall, not into the room',
      );
    });
  });
}
