import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/gallery_camera_path.dart';
import 'package:portfolio/domain/gallery/gallery_dimensions.dart';
import 'package:portfolio/domain/gallery/wall_steps.dart';
import 'package:portfolio/domain/utils/scroll_driver.dart';
import 'package:portfolio/domain/utils/strokes.dart';

const extent = 8000.0;

void main() {
  final points = WallSteps.points(extent);

  test('the back wall, then every card, the heading card first', () {
    expect(points.length, 1 + GalleryDimensions.testimonialCount);
    expect(points.first, GalleryCameraPath.walkFraction * extent);
    for (var i = 1; i < points.length; i++) {
      expect(points[i], greaterThan(points[i - 1]));
    }
  });

  test('each card step centres the camera on that card', () {
    for (var i = 0; i < GalleryDimensions.testimonialCount; i++) {
      final pose = GalleryCameraPath.poseAt(
        points[i + 1] / extent,
        aspect: 0.54,
      );
      final x =
          GalleryDimensions.testStartX + i * GalleryDimensions.testSpacing;
      expect(pose.position.x, closeTo(x, 1e-3), reason: 'card $i');
      expect(pose.target.x, closeTo(x, 1e-3), reason: 'square on');
    }
  });

  test('next and previous step along the wall, and stop at its ends', () {
    expect(WallSteps.next(points[0], points), points[1]);
    expect(WallSteps.next(points[2], points), points[3]);
    expect(WallSteps.previous(points[1], points), points[0]);
    // Past the first card: back to the back wall; before it, nothing.
    expect(WallSteps.previous(points[0], points), isNull);
    // Past the last card the wall has no step; the walk carries on.
    expect(WallSteps.next(points.last, points), isNull);
    // Between two cards, the nearer ones either way.
    final between = (points[2] + points[3]) / 2;
    expect(WallSteps.next(between, points), points[3]);
    expect(WallSteps.previous(between, points), points[2]);
  });

  test('off the wall, nothing steps', () {
    expect(WallSteps.onWall(points.first - 100, points), isFalse);
    expect(WallSteps.next(points.first - 100, points), isNull);
    expect(WallSteps.onWall(points.last + 100, points), isFalse);
  });

  test('the stick steps once it is pushed past half', () {
    expect(WallSteps.stickDirection(0.3), 0);
    expect(WallSteps.stickDirection(0.8), 1);
    expect(WallSteps.stickDirection(-0.8), -1);
  });

  test('a step is the strokes\' timed move, landing on the card', () {
    final driver = ScrollDriver(
      extent: extent,
      progressExtent: extent,
      snapPoints: <double>[points.first],
    )..scrollBy(points.first);
    for (var i = 0; i < 30; i++) {
      driver.update(1 / 40);
    }
    driver.moveTo(points[1]);
    expect(driver.isMoving, isTrue);
    for (var t = 0.0; t < Strokes.moveSeconds + 0.1; t += 1 / 40) {
      driver.update(1 / 40);
    }
    expect(driver.isMoving, isFalse);
    expect(driver.offset, points[1]);
    // And it stays there: no pause takes the camera back.
    for (var i = 0; i < 80; i++) {
      driver.update(1 / 40);
    }
    expect(driver.offset, points[1]);
  });
}
