import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/config/bold_text_config.dart';
import 'package:portfolio/domain/gallery/gallery_camera_path.dart';
import 'package:portfolio/domain/utils/scroll_driver.dart';
import 'package:portfolio/presentation/gallery/gallery_view.dart';

/// The corridor's driver, built the way the view builds it.
ScrollDriver corridor() => ScrollDriver(
  extent: GalleryView.scrollExtent,
  progressExtent: GalleryView.scrollExtent,
  snapPoints: <double>[GalleryView.backWallStop],
);

/// Runs the driver for [seconds] at sixty frames.
void run(ScrollDriver driver, double seconds) {
  for (var i = 0; i < (seconds * 60).round(); i++) {
    driver.update(1 / 60);
  }
}

/// Runs on until the wall takes hold, or gives up.
///
/// How many frames that takes is a property of how the motion is smoothed,
/// not something a test about the wall should be pinning.
bool runUntilSnapping(ScrollDriver driver, {int maxFrames = 120}) {
  for (var i = 0; i < maxFrames; i++) {
    driver.update(1 / 60);
    if (driver.isSnapping) return true;
  }
  return false;
}

void main() {
  group('the pause at the far wall', () {
    test('sits where the walk ends, not somewhere near it', () {
      // Derived from the camera path. A pause at a position the camera no
      // longer stops at holds the visitor in the middle of a turn.
      expect(
        GalleryView.backWallStop / GalleryView.scrollExtent,
        GalleryCameraPath.walkFraction,
      );
    });

    test('is the only one — the rest of the corridor is a walk', () {
      // Halting at fixed frames elsewhere would fight the scroll. The far
      // wall is the one place there is something to read.
      expect(corridor().snapPoints, hasLength(1));
    });

    test('catches a visitor who arrives and stops', () {
      final driver = corridor();

      // Scrolled to just short of the wall, then let go.
      driver.scrollBy(GalleryView.backWallStop - 200);
      run(driver, 2);

      expect(
        driver.target,
        closeTo(GalleryView.backWallStop, 1),
        reason: 'the wall did not take hold',
      );
    });

    test('catches an ordinary scroll on its way past', () {
      final driver = corridor();

      // 40 units a frame — 2400 a second, a brisk but ordinary scroll. This
      // is the case the wall exists for and the one that used to miss: the
      // old gate only admitted a scroll already at a standstill, so whether
      // it fired came down to whether a still frame happened to land inside
      // the catchment.
      var caught = false;
      for (var i = 0; i < 120 && !caught; i++) {
        driver.scrollBy(40);
        driver.update(1 / 60);
        caught = driver.isSnapping;
      }

      expect(caught, isTrue);
    });

    test('lets a deliberate fling through', () {
      final driver = corridor();

      // 120 a frame is 7200 a second, past even the braking gate. Someone
      // moving that fast has decided where they are going, and being yanked
      // back to a wall behind them reads as the page arguing.
      for (var i = 0; i < 40; i++) {
        driver.scrollBy(120);
        driver.update(1 / 60);
      }

      expect(driver.target, greaterThan(GalleryView.backWallStop));
      expect(driver.isSnapping, isFalse);
    });

    test('holds the scroll while it draws in, and lets go once parked', () {
      final driver = corridor();
      driver.scrollBy(GalleryView.backWallStop - 200);

      // The window this opens is what the sound is hung on — the wall taking
      // hold, not the camera arriving, because the deceleration is the part
      // that reads as being caught.
      expect(runUntilSnapping(driver), isTrue);

      // And released once it has settled, so the flag is free to rise again
      // the next time the visitor comes back to the wall.
      run(driver, 3);
      expect(driver.isSnapping, isFalse);
      expect(driver.target, closeTo(GalleryView.backWallStop, 1));
    });

    test('lets go the moment the visitor scrolls on', () {
      final driver = corridor();
      driver.scrollBy(GalleryView.backWallStop - 200);
      expect(runUntilSnapping(driver), isTrue);

      // Reading is over. A pause that has to be fought out of reads as the
      // page holding on rather than as somewhere to rest.
      driver.scrollBy(300);
      expect(driver.isSnapping, isFalse);
      expect(driver.target, greaterThan(GalleryView.backWallStop));
    });

    test('is reached before the board is ever mentioned', () {
      // Two things now claim the scroll on the way down the corridor. If the
      // pause sat past the point the board starts rising, the visitor would
      // be held still while it came up behind them.
      expect(
        GalleryView.backWallStop / GalleryView.scrollExtent,
        lessThan(GalleryCameraPath.revealBegins),
      );
    });

    test('its catchment does not reach back to the entrance', () {
      // `snapRadius` is shared with the bold-text stage, whose travel is a
      // different length — so the same number is a different share of this
      // corridor, and a radius that swallowed the entrance would drag a
      // visitor who had only just started forward to the far wall.
      expect(
        GalleryView.backWallStop - BoldTextConfig.snapRadius,
        greaterThan(0),
      );
    });
  });
}
