import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/config/bold_text_config.dart';
import 'package:portfolio/domain/utils/scroll_driver.dart';

/// Runs the driver for [seconds] at a steady 60fps.
void settle(ScrollDriver driver, {double seconds = 4}) {
  const step = 1 / 60;
  for (var t = 0.0; t < seconds; t += step) {
    driver.update(step);
  }
}

void main() {
  late ScrollDriver driver;

  setUp(() => driver = ScrollDriver());

  group('ScrollDriver', () {
    test('starts at the beginning', () {
      expect(driver.offset, 0);
      expect(driver.progress, 0);
      expect(driver.isComplete, isFalse);
    });

    test('the scene lags the input rather than teleporting', () {
      // The gap between target and offset is the weight. Without it a
      // trackpad flick would jump the whole sequence in one frame.
      driver.scrollBy(1000);

      expect(driver.target, 1000);
      expect(driver.offset, 0, reason: 'nothing has been rendered yet');

      driver.update(1 / 60);
      expect(driver.offset, greaterThan(0));
      expect(driver.offset, lessThan(1000));
    });

    test('the scene catches up given time', () {
      driver.scrollBy(600);
      settle(driver);

      expect(driver.offset, closeTo(driver.target, 1));
    });

    test('scroll is clamped to the stage', () {
      driver.scrollBy(99999);
      expect(driver.target, BoldTextConfig.extent);

      driver.scrollBy(-99999);
      expect(driver.target, 0);
    });

    test('progress maps the scene onto the shader range', () {
      driver.scrollBy(BoldTextConfig.progressExtent);
      settle(driver);

      expect(driver.progress, closeTo(1, 0.01));
    });

    test('progress stays finished across the dead tail', () {
      // The stage scrolls further than the sequence lasts, so the last
      // stretch confirms the user meant to leave rather than wrapping around.
      expect(BoldTextConfig.extent, greaterThan(BoldTextConfig.progressExtent));

      driver.scrollBy(BoldTextConfig.extent);
      settle(driver);

      expect(driver.progress, 1);
    });
  });

  group('pauses', () {
    test('settles onto the nearest pause once the scroll slows', () {
      // Landing just short of the focus point should be claimed by it.
      driver.scrollBy(1300);
      settle(driver);

      expect(driver.target, closeTo(1500, 1));
    });

    test('a scroll well clear of a pause is left alone', () {
      const free = 900.0; // outside both snap radii
      driver.scrollBy(free);
      settle(driver);

      expect(driver.target, closeTo(free, 1));
    });

    test('scrolling away from a pause is not fought', () {
      // Being pulled back toward a pause the user is actively leaving reads
      // as the page arguing with them.
      driver.scrollBy(1450);

      // Two frames without input, so the scroll reads as having come to rest
      // rather than as passing through. This used to pass on the very first
      // frame, which was the bug: velocity was measured across the spring
      // alone, so a scroll travelling at 87,000 units a second reported
      // zero and every pause concluded the visitor had stopped.
      driver.update(1 / 60);
      driver.update(1 / 60);
      expect(driver.isSnapping, isTrue);

      driver.scrollBy(-600);
      expect(driver.isSnapping, isFalse);
    });

    test('a pause let go of does not take the scroll straight back', () {
      driver.scrollBy(1450);
      driver.update(1 / 60);
      driver.update(1 / 60);
      expect(driver.isSnapping, isTrue);

      // A small deliberate nudge, then rest. The pause is still well within
      // reach, and letting it reacquire here would mean nothing short of a
      // scroll clear across its catchment could ever escape it.
      driver.scrollBy(-60);
      final afterNudge = driver.target;
      for (var i = 0; i < 10; i++) {
        driver.update(1 / 60);
      }

      expect(driver.isSnapping, isFalse);
      // Exactly where the nudge left it. Nothing is pulling on it, so the
      // target does not move at all — the offset chases it, not the reverse.
      expect(driver.target, afterNudge);
    });

    test('but takes hold again once the visitor comes back to it', () {
      driver.scrollBy(1450);
      driver.update(1 / 60);
      driver.update(1 / 60);
      driver.scrollBy(-60);
      driver.update(1 / 60);
      expect(driver.isSnapping, isFalse);

      // Right out of its catchment and back in. Released is not forgotten,
      // it is a hold that lasts as long as the visitor stays near.
      driver.scrollBy(-900);
      driver.update(1 / 60);
      driver.scrollBy(900);
      settle(driver);

      expect(driver.target, closeTo(1500, 1));
    });

    test('reports the speed the visitor is actually scrolling at', () {
      // Read by the bold-text swell to decide how loud it is, so a velocity
      // that ignored the visitor made a fast scroll as quiet as a still one.
      driver.scrollBy(100);
      driver.update(1 / 60);
      expect(driver.velocity, closeTo(6000, 1));
    });

    test('a scroll passing through at speed is not caught', () {
      final passing = ScrollDriver();

      var acquisitions = 0;
      var was = false;
      for (var i = 0; i < 120; i++) {
        passing.scrollBy(40);
        passing.update(1 / 60);
        if (passing.isSnapping && !was) acquisitions++;
        was = passing.isSnapping;
      }

      // Thirteen, before the two fixes above: the pause grabbed on every
      // frame the visitor scrolled through its catchment, and each grab was
      // a sound.
      expect(acquisitions, 0);
    });
  });

  group('the arrow', () {
    test('steps to the first pause', () {
      driver.advanceToNextPause();
      settle(driver);

      expect(driver.target, closeTo(1500, 1));
      expect(driver.isComplete, isFalse);
    });

    test('steps from the first pause to the end', () {
      driver.advanceToNextPause();
      settle(driver);
      driver.advanceToNextPause();
      settle(driver);

      expect(driver.target, closeTo(BoldTextConfig.extent, 1));
      expect(driver.isComplete, isTrue);
    });

    test('lands on the same places scrolling would', () {
      // Clicking and scrolling must not diverge — they are two ways to ask
      // for the same thing.
      final clicked = ScrollDriver()..advanceToNextPause();
      settle(clicked);

      final scrolled = ScrollDriver()..scrollBy(1400);
      settle(scrolled);

      expect(clicked.target, closeTo(scrolled.target, 1));
    });

    test('does nothing more once the stage is spent', () {
      driver
        ..advanceToNextPause()
        ..advanceToNextPause();
      settle(driver);

      driver.advanceToNextPause();
      settle(driver);

      expect(driver.target, closeTo(BoldTextConfig.extent, 1));
    });
  });

  group('stability', () {
    test('survives the long frame a backgrounded tab hands back', () {
      driver.scrollBy(1500);
      driver.update(5);

      expect(driver.offset.isFinite, isTrue);
      expect(driver.offset, inInclusiveRange(0, BoldTextConfig.extent));
    });

    test('never leaves the stage, however it is driven', () {
      for (var i = 0; i < 300; i++) {
        driver.scrollBy(i.isEven ? 400 : -250);
        driver.update(1 / 60);

        expect(driver.offset, inInclusiveRange(-1, BoldTextConfig.extent + 1));
        expect(driver.progress, inInclusiveRange(0, 1));
      }
    });

    test('reset returns it to the start', () {
      driver.scrollBy(2000);
      settle(driver);

      driver.reset();

      expect(driver.offset, 0);
      expect(driver.target, 0);
      expect(driver.progress, 0);
      expect(driver.isSnapping, isFalse);
    });
  });

  group('the arrow outlives the gesture it invited', () {
    test('stays fully visible at the first pause', () {
      // Regression guard. The second half of the sequence is reached by
      // clicking the arrow *again*, so fading it once the user starts
      // scrolling strands anyone without a wheel — they reach the pause and
      // the only way onward has disappeared.
      final atPause = BoldTextConfig.snapPoints.last /
          BoldTextConfig.progressExtent;

      expect(BoldTextConfig.cueVisibility(atPause), 1);
    });

    test('stays visible through the whole first half', () {
      for (var p = 0.0; p <= BoldTextConfig.splashStart; p += 0.05) {
        expect(
          BoldTextConfig.cueVisibility(p),
          1,
          reason: 'hidden at progress $p',
        );
      }
    });

    test('clears with the final flash, when everything else does', () {
      expect(BoldTextConfig.cueVisibility(0.95), lessThan(1));
      expect(BoldTextConfig.cueVisibility(1), 0);
    });

    test('the pause is inside the shader window where the text rests', () {
      // The pause has to land on the text at rest, not mid-animation: the
      // shader settles between 0.45 and 0.6 of progress.
      final atPause = BoldTextConfig.snapPoints.last /
          BoldTextConfig.progressExtent;

      expect(atPause, greaterThan(0.45));
      expect(atPause, lessThan(0.6));
    });
  });
}
