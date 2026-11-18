import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/gallery_camera_path.dart';
import 'package:portfolio/domain/gallery/walk_control.dart';
import 'package:portfolio/domain/utils/scroll_driver.dart';
import 'package:portfolio/presentation/gallery/gallery_view.dart';

void main() {
  test('a full push, before the run, walks the corridor in 6.3 s', () {
    // The corridor's walk, in the gallery's own scroll units.
    expect(
      WalkControl.corridorUnits,
      closeTo(GalleryView.scrollExtent * GalleryCameraPath.walkFraction, 1),
    );
    expect(
      WalkControl.corridorUnits / WalkControl.maxSpeed,
      closeTo(WalkControl.corridorSeconds, 1e-9),
    );
    expect(WalkControl.corridorSeconds, 6.3);
  });

  test('a small push walks slowly, a full one briskly', () {
    expect(WalkControl.response(1), 1);
    expect(WalkControl.response(-1), -1);
    expect(WalkControl.response(0.5), lessThan(0.3));
    expect(WalkControl.response(0.5), greaterThan(0.15));
    expect(WalkControl.response(0), 0);
  });

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

  test('a held stick stops at the back wall, and walks on after', () {
    const stop = 3480.0;
    // Short of it: the whole step.
    expect(WalkControl.stepToStop(3000, 20, stop), 20);
    // Crossing it: lands on it.
    expect(WalkControl.stepToStop(3470, 20, stop), 10);
    // On it, pushed again: walks on.
    expect(WalkControl.stepToStop(stop, 20, stop), 20);
    // Backward is never held.
    expect(WalkControl.stepToStop(3490, -20, stop), -20);
  });
}
