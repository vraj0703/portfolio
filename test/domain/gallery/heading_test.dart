import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/gallery_camera_path.dart';
import 'package:portfolio/domain/gallery/swipe_map.dart';
import 'package:portfolio/domain/gallery/walk_control.dart';

void main() {
  const extent = 8000.0;
  final stop = GalleryCameraPath.walkFraction * extent;

  /// The stick's axes at scroll position [at], as the gallery reads them.
  (ScreenAxis, ScreenAxis) axesAt(double at, {double aspect = 0.5}) {
    final p = at / extent;
    final here = GalleryCameraPath.poseAt(p, aspect: aspect);
    final look = here.target - here.position;
    return (
      SwipeMap.travelAxis(GalleryCameraPath.headingAt((at + 1) / extent), look),
      SwipeMap.travelAxis(GalleryCameraPath.headingAt((at - 1) / extent), look),
    );
  }

  test('a stick held up stops at the back wall, through the step-in too', () {
    // Found on the Pixel profile: read from the camera's motion, the steep
    // step-in counted as "up" and the stick crept off the stop along it.
    for (final aspect in <double>[0.42, 0.5, 0.54, 16 / 9]) {
      for (final at in <double>[stop, stop + 0.5, stop + 50, stop + 200]) {
        final (ahead, behind) = axesAt(at, aspect: aspect);
        expect(
          WalkControl.rate((x: 0, y: 1), ahead, behind),
          lessThanOrEqualTo(1e-6),
          reason: 'aspect $aspect at ${at - stop} past the stop',
        );
      }
    }
  });

  test('and walks up the corridor before it, glides along the wall after', () {
    final (cAhead, cBehind) = axesAt(stop - 400);
    expect(WalkControl.rate((x: 0, y: 1), cAhead, cBehind), closeTo(1, 1e-6));
    final (wAhead, wBehind) = axesAt(stop + 600);
    expect(WalkControl.rate((x: 1, y: 0), wAhead, wBehind), closeTo(1, 1e-6));
    final (sAhead, sBehind) = axesAt(stop);
    expect(WalkControl.rate((x: 1, y: 0), sAhead, sBehind), closeTo(1, 1e-6));
    expect(WalkControl.rate((x: 0, y: -1), sAhead, sBehind), closeTo(-1, 1e-6));
  });
}
