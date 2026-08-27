import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/config/cursor_config.dart';
import 'package:portfolio/presentation/game/cursor_tracker.dart';

final Vector2 viewport = Vector2(1280, 720);

void settle(CursorTracker tracker, {double seconds = 2}) {
  const step = 1 / 60;
  for (var t = 0.0; t < seconds; t += step) {
    tracker.update(step);
  }
}

void main() {
  group('CursorTracker', () {
    late CursorTracker tracker;

    setUp(() {
      tracker = CursorTracker()..reset(viewport / 2);
    });

    test('starts centred and reports no pointer yet', () {
      expect(tracker.position, viewport / 2);
      expect(tracker.hasPointer, isFalse);
    });

    test('notices the pointer once it moves', () {
      tracker.moveTo(Vector2(100, 100), viewport);
      expect(tracker.hasPointer, isTrue);
    });

    test('eases toward the pointer rather than snapping', () {
      final start = tracker.position.clone();
      tracker.moveTo(Vector2(1200, 650), viewport);
      tracker.update(1 / 60);

      expect(tracker.position, isNot(start));
      expect(
        (tracker.position - tracker.target).length,
        greaterThan(1),
        reason: 'one frame should not arrive',
      );
    });

    test('arrives at the pointer given time', () {
      tracker.moveTo(Vector2(1000, 200), viewport);
      settle(tracker);

      expect((tracker.position - tracker.target).length, lessThan(1));
    });

    test('sits below the pointer so the mark is lit from above', () {
      const pointerY = 300.0;
      tracker.moveTo(Vector2(640, pointerY), viewport);
      settle(tracker);

      expect(tracker.position.y, closeTo(pointerY + CursorConfig.glowOffset, 1));
    });

    test('points away from the centre', () {
      tracker.moveTo(Vector2(1280, 360), viewport);
      settle(tracker);

      // Pointer is due right of centre.
      expect(tracker.direction.x, closeTo(1, 0.05));
      expect(tracker.direction.y, closeTo(0, 0.05));
      expect(tracker.direction.length, closeTo(1, 0.05));
    });

    test('survives the long frame a backgrounded tab hands back', () {
      tracker.moveTo(Vector2(1200, 700), viewport);
      tracker.update(5);

      expect(tracker.position.x.isFinite, isTrue);
      expect(tracker.position.y.isFinite, isTrue);
      // Clamped, so a stalled frame cannot teleport it past the target.
      expect(tracker.position.x, lessThanOrEqualTo(tracker.target.x + 1));
    });

    test('never overshoots the pointer', () {
      tracker.moveTo(Vector2(1280, 720), viewport);
      for (var i = 0; i < 200; i++) {
        tracker.update(1 / 60);
        expect(tracker.position.x, lessThanOrEqualTo(tracker.target.x + 0.5));
        expect(tracker.position.y, lessThanOrEqualTo(tracker.target.y + 0.5));
      }
    });

    group('parallax', () {
      test('is zero at the centre', () {
        final offset = tracker.parallax(viewport, CursorConfig.titleParallax);
        expect(offset.length, closeTo(0, 0.001));
      });

      test('grows with distance from the centre', () {
        tracker.moveTo(Vector2(1280, 360), viewport);
        settle(tracker);

        final offset = tracker.parallax(viewport, CursorConfig.titleParallax);
        expect(offset.x, greaterThan(0));
        expect(offset.x, closeTo(640 * CursorConfig.titleParallax, 1));
      });

      test('moves the secondary line less, which is what reads as depth', () {
        tracker.moveTo(Vector2(1280, 360), viewport);
        settle(tracker);

        final primary = tracker.parallax(
          viewport,
          CursorConfig.titleParallax,
        );
        final secondary = tracker.parallax(
          viewport,
          CursorConfig.secondaryTitleParallax,
        );

        expect(secondary.x.abs(), lessThan(primary.x.abs()));
      });

      test('inverts on the opposite side', () {
        tracker.moveTo(Vector2(0, 360), viewport);
        settle(tracker);

        final offset = tracker.parallax(viewport, CursorConfig.titleParallax);
        expect(offset.x, lessThan(0));
      });
    });
  });
}
