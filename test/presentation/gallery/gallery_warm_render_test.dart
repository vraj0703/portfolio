import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/gallery_camera_path.dart';
import 'package:portfolio/domain/gallery/gallery_dimensions.dart';
import 'package:portfolio/presentation/gallery/gallery_warm_render.dart';

void main() {
  group('the warm camera walks the whole corridor', () {
    test('it starts at the entrance and reaches the far end', () {
      // Parked at the entrance it warmed the first wall and nothing else,
      // because `flutter_scene` culls against the view frustum — so the
      // hitch simply moved down the corridor to the second or third picture.
      expect(GalleryWarmRender.progressAt(Duration.zero), 0);
      expect(GalleryWarmRender.progressAt(GalleryWarmRender.sweep), 1);
    });

    test('and holds there rather than walking back', () {
      // Everything has been submitted by the end of the sweep. A camera
      // still moving behind the curtain is work with nothing left to warm.
      expect(
        GalleryWarmRender.progressAt(GalleryWarmRender.sweep * 4),
        1,
        reason: 'the sweep ran past its end instead of holding',
      );
    });

    test('never running backwards on the way', () {
      var previous = -1.0;
      for (var frame = 0; frame <= 240; frame++) {
        final at = GalleryWarmRender.progressAt(
          Duration(microseconds: (frame * 1e6 ~/ 60)),
        );
        expect(at, greaterThanOrEqualTo(previous));
        previous = at;
      }
    });

    test('and stepping over nothing between one frame and the next', () {
      // The real guarantee. A sweep short enough to skip a stretch of wall
      // between frames would leave whatever hangs there unwarmed, and the
      // hitch would come back somewhere further along — the same bug with a
      // different address.
      //
      // Measured against the gap between pictures: as long as the camera
      // advances less than that in a frame, no picture can be jumped past.
      const frame = Duration(microseconds: 1000000 ~/ 60);
      var worst = 0.0;

      for (var i = 0; i < 240; i++) {
        final here = GalleryCameraPath.poseAt(
          GalleryWarmRender.progressAt(frame * i),
        );
        final next = GalleryCameraPath.poseAt(
          GalleryWarmRender.progressAt(frame * (i + 1)),
        );

        final step = (next.position - here.position).length;
        if (step > worst) worst = step;
      }

      expect(
        worst,
        lessThan(GalleryDimensions.spacing),
        reason:
            'the camera moves ${worst.toStringAsFixed(2)} units a frame, '
            'past pictures ${GalleryDimensions.spacing} apart',
      );
    });
  });
}
