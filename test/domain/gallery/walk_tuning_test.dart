import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/gallery_camera_path.dart';
import 'package:portfolio/domain/gallery/walk_control.dart';
import 'package:portfolio/domain/utils/scroll_driver.dart';
import 'package:portfolio/presentation/gallery/gallery_view.dart';

void main() {
  test('a full push walks the corridor in about 15 s', () {
    // The corridor's walk, in the gallery's own scroll units.
    expect(
      WalkControl.corridorUnits,
      closeTo(GalleryView.scrollExtent * GalleryCameraPath.walkFraction, 1),
    );
    expect(
      WalkControl.corridorUnits / WalkControl.maxSpeed,
      closeTo(WalkControl.corridorSeconds, 1e-9),
    );
    expect(WalkControl.corridorSeconds, 15);
  });

  test('letting go stops within a quarter of a second, camera included', () {
    // The walk's own ease-out, plus the camera's tight chase settling to
    // within 1% (ln 100 / rate seconds).
    final cameraSettle = math.log(100) / WalkControl.stickChase;
    expect(WalkControl.stopSeconds + cameraSettle, lessThanOrEqualTo(0.25));
    expect(WalkControl.stopSeconds, lessThanOrEqualTo(0.15));
  });

  test(
    'the look reaches 35 degrees at a full-width drag, after a dead zone',
    () {
      const width = 400.0;
      expect(WalkControl.look(WalkControl.lookDeadZone, width), 0);
      expect(
        WalkControl.look(width + WalkControl.lookDeadZone, width),
        closeTo(WalkControl.maxLook, 1e-9),
      );
      expect(
        WalkControl.look(width / 3, width),
        lessThan(WalkControl.maxLook / 2),
      );
      expect(WalkControl.maxLook, closeTo(35 * math.pi / 180, 1e-12));
    },
  );

  test('a tight update puts the offset on the target, with no glide', () {
    final driver = ScrollDriver(extent: 8000, progressExtent: 8000);
    driver.scrollBy(500);
    driver.update(1 / 60, tight: true);
    expect(driver.offset, driver.target);

    // The default still chases: the wheel and tap-to-frame keep the spring.
    final soft = ScrollDriver(extent: 8000, progressExtent: 8000)
      ..scrollBy(500);
    soft.update(1 / 60);
    expect(soft.offset, lessThan(soft.target));
  });
}
