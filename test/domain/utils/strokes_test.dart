import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/config/bold_text_config.dart';
import 'package:portfolio/domain/utils/scroll_driver.dart';
import 'package:portfolio/domain/utils/strokes.dart';

/// Runs [driver] for [seconds] at [fps].
void run(ScrollDriver driver, double seconds, {double fps = 40}) {
  for (var t = 0.0; t < seconds; t += 1 / fps) {
    driver.update(1 / fps);
  }
}

void main() {
  group('Strokes', () {
    test('a drag is a stroke once it is long enough to say which way', () {
      expect(Strokes.dragDirection(-10), 0);
      expect(Strokes.dragDirection(-Strokes.dragThreshold), 1);
      expect(Strokes.dragDirection(Strokes.dragThreshold + 1), -1);
    });

    test('a wheel burst is one stroke; a pause starts the next', () {
      expect(Strokes.wheelStartsStroke(1000, null), isTrue);
      expect(Strokes.wheelStartsStroke(1100, 1000), isFalse);
      expect(
        Strokes.wheelStartsStroke(1000 + Strokes.wheelBurstGapMs + 1, 1000),
        isTrue,
      );
      expect(Strokes.wheelDirection(120), 1);
      expect(Strokes.wheelDirection(-3), -1);
      expect(Strokes.wheelDirection(0), 0);
    });

    test('a move is eased in and out, and timed between 0.8 and 1 s', () {
      expect(Strokes.moveSeconds, inInclusiveRange(0.8, 1.0));
      expect(Strokes.eased(0), 0);
      expect(Strokes.eased(Strokes.moveSeconds / 2), closeTo(0.5, 1e-9));
      expect(Strokes.eased(Strokes.moveSeconds), 1);
      // Slow to start and to finish.
      expect(Strokes.eased(Strokes.moveSeconds * 0.1), lessThan(0.05));
      expect(Strokes.eased(Strokes.moveSeconds * 0.9), greaterThan(0.95));
    });
  });

  group('the title to the gallery in two strokes', () {
    test('the first stroke reaches the bold text, the second completes', () {
      final driver = ScrollDriver();
      driver.advanceToNextPause();
      run(driver, Strokes.moveSeconds + 0.1);
      expect(driver.offset, BoldTextConfig.snapPoints[1]);
      expect(driver.isMoving, isFalse);
      expect(driver.isComplete, isFalse);

      driver.advanceToNextPause();
      run(driver, Strokes.moveSeconds + 0.1);
      expect(driver.isComplete, isTrue);
    });

    test('and it stays at the bold text, rather than a pause taking hold', () {
      final driver = ScrollDriver()..advanceToNextPause();
      run(driver, Strokes.moveSeconds + 1.5);
      expect(driver.offset, BoldTextConfig.snapPoints[1]);
      expect(driver.isSnapping, isFalse);
    });

    test('a move takes its time whatever the frame rate', () {
      for (final fps in <double>[25, 40, 60, 120]) {
        final driver = ScrollDriver()..advanceToNextPause();
        run(driver, Strokes.moveSeconds / 2, fps: fps);
        expect(
          driver.offset / BoldTextConfig.snapPoints[1],
          closeTo(0.5, 0.15),
          reason: '$fps fps',
        );
      }
    });

    test('a stroke back returns to the previous pause', () {
      final driver = ScrollDriver()..advanceToNextPause();
      run(driver, Strokes.moveSeconds + 0.1);
      driver.retreatToPreviousPause();
      run(driver, Strokes.moveSeconds + 0.1);
      expect(driver.offset, 0);
    });

    test('a deliberate scroll takes over from a move', () {
      final driver = ScrollDriver()..advanceToNextPause();
      run(driver, 0.2);
      driver.scrollBy(10);
      expect(driver.isMoving, isFalse);
    });
  });
}
