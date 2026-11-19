import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/gallery_camera_path.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';
import 'package:portfolio/domain/gallery/gallery_shape.dart';
import 'package:portfolio/domain/gallery/swipe_map.dart';
import 'package:portfolio/domain/gallery/walk_order.dart';
import 'package:vector_math/vector_math.dart';

/// The way of travel on screen at [progress], as the view works it out.
ScreenAxis axisAt(double progress, {double aspect = 0.5}) {
  final here = GalleryCameraPath.poseAt(progress, aspect: aspect);
  final ahead = GalleryCameraPath.poseAt(progress + 0.002, aspect: aspect);
  return SwipeMap.travelAxis(
    ahead.position - here.position,
    here.target - here.position,
  );
}

void main() {
  group('the way of travel on screen', () {
    test('down the corridor it runs into the screen: vertical', () {
      final axis = axisAt(0.2);
      expect(axis.x, closeTo(0, 1e-6));
      expect(axis.y, closeTo(1, 1e-6));
    });

    test('along the testimonial wall it runs across: horizontal', () {
      final axis = axisAt(
        GalleryCameraPath.walkFraction + GalleryCameraPath.panFraction / 2,
      );
      expect(axis.x, closeTo(1, 1e-6));
      expect(axis.y, closeTo(0, 1e-6));
    });

    test('at the back wall it has already turned sideways', () {
      final axis = axisAt(GalleryCameraPath.walkFraction);
      expect(axis.x.abs(), greaterThan(axis.y.abs()));
    });

    test('a camera looking down -z sees +x as right', () {
      final axis = SwipeMap.travelAxis(Vector3(1, 0, 0), Vector3(0, 0, -1));
      expect(axis.x, 1);
    });
  });

  group('what a swipe means', () {
    const corridor = (x: 0.0, y: 1.0);
    const wall = (x: 1.0, y: 0.0);

    test('a wobble means nothing', () {
      expect(SwipeMap.classify(5, -10, corridor), SwipeIntent.none);
    });

    test('in the corridor, up travels; sideways picks a side', () {
      expect(SwipeMap.classify(4, -80, corridor), SwipeIntent.travel);
      expect(SwipeMap.classify(80, 10, corridor), SwipeIntent.focusRight);
      expect(SwipeMap.classify(-80, 10, corridor), SwipeIntent.focusLeft);
    });

    test('along the wall, sideways travels; up and down mean nothing', () {
      expect(SwipeMap.classify(-80, 6, wall), SwipeIntent.travel);
      expect(SwipeMap.classify(80, 6, wall), SwipeIntent.travel);
      expect(SwipeMap.classify(5, -80, wall), SwipeIntent.none);
    });

    test('the room follows the finger', () {
      // Corridor: finger up, onward. Wall: finger left (the room moving
      // left), onward along it.
      expect(SwipeMap.onward(0, -50, corridor), greaterThan(0));
      expect(SwipeMap.onward(0, 50, corridor), lessThan(0));
      expect(SwipeMap.onward(-50, 0, wall), greaterThan(0));
      expect(SwipeMap.onward(50, 0, wall), lessThan(0));
      expect(SwipeMap.onward(0, -50, corridor), 50 * SwipeMap.travelGain);
    });
  });

  group('the nearest frame on a side', () {
    final order = WalkOrder(GalleryLayout.build(shape: GalleryShape.portrait));

    test('is on that side, nearest the eye', () {
      for (final z in <double>[0, -10, -25]) {
        final right = order.nearestOn(right: true, z: z)!;
        final left = order.nearestOn(right: false, z: z)!;
        expect(right.position.x, greaterThan(0));
        expect(left.position.x, lessThan(0));
        for (final f in order.frames.where((f) => f.position.x > 0)) {
          expect(
            (right.position.z - z).abs(),
            lessThanOrEqualTo((f.position.z - z).abs()),
          );
        }
      }
    });
  });
}
