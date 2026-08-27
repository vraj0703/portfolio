import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/config/secondary_title_timeline.dart';

void main() {
  group('SecondaryTitleTimeline', () {
    const glyphs = 19; // "Welcome to my space"

    test('nothing has started at zero', () {
      expect(SecondaryTitleTimeline.opacityOf(0, 0), 0);
      expect(
        SecondaryTitleTimeline.riseOf(0, 0),
        SecondaryTitleTimeline.riseFrom,
      );
    });

    test('glyphs start in order, not together', () {
      // The stagger is the whole effect — without it the line just appears.
      expect(SecondaryTitleTimeline.startOf(0), 0);
      expect(
        SecondaryTitleTimeline.startOf(5),
        greaterThan(SecondaryTitleTimeline.startOf(4)),
      );
    });

    test('a later glyph lags an earlier one', () {
      const t = 0.3;
      expect(
        SecondaryTitleTimeline.opacityOf(t, 0),
        greaterThan(SecondaryTitleTimeline.opacityOf(t, 4)),
      );
    });

    test('a glyph whose turn has not come is still invisible', () {
      expect(SecondaryTitleTimeline.opacityOf(0.1, 10), 0);
    });

    test('each glyph rises to its resting line', () {
      final settled = SecondaryTitleTimeline.perGlyph + 1;
      expect(SecondaryTitleTimeline.riseOf(settled, 0), closeTo(0, 0.01));
    });

    test('the line slides in from the left and arrives', () {
      expect(
        SecondaryTitleTimeline.slideOffset(0),
        SecondaryTitleTimeline.slideFrom,
      );
      expect(
        SecondaryTitleTimeline.slideOffset(
          SecondaryTitleTimeline.slideDuration,
        ),
        closeTo(0, 0.01),
      );
    });

    test('squashes before it settles', () {
      // The squash is what gives the elastic something to spring back from.
      // Without it the settle reads as a wobble rather than as weight.
      final mid = SecondaryTitleTimeline.squashDuration * 0.9;
      expect(SecondaryTitleTimeline.scaleYOf(mid, 0), greaterThan(1));
      expect(SecondaryTitleTimeline.scaleXOf(mid, 0), lessThan(1));
    });

    test('settles back to its natural size', () {
      final settled = SecondaryTitleTimeline.perGlyph + 2;
      expect(SecondaryTitleTimeline.scaleXOf(settled, 0), closeTo(1, 0.001));
      expect(SecondaryTitleTimeline.scaleYOf(settled, 0), closeTo(1, 0.001));
    });

    test('the elastic settle overshoots, which is what makes it elastic', () {
      var sawOvershoot = false;
      final from = SecondaryTitleTimeline.squashDuration;
      final to = from + SecondaryTitleTimeline.settleDuration;

      for (var t = from; t < to; t += 1 / 120) {
        if (SecondaryTitleTimeline.scaleYOf(t, 0) < 1) {
          sawOvershoot = true;
          break;
        }
      }
      expect(sawOvershoot, isTrue);
    });

    test('opacity stays in bounds throughout', () {
      final total = SecondaryTitleTimeline.durationFor(glyphs);
      for (var t = -1.0; t <= total + 2; t += 1 / 60) {
        for (var i = 0; i < glyphs; i++) {
          expect(
            SecondaryTitleTimeline.opacityOf(t, i),
            inInclusiveRange(0, 1),
            reason: 'glyph $i at $t',
          );
        }
      }
    });

    test('completes only after the last glyph has settled', () {
      final total = SecondaryTitleTimeline.durationFor(glyphs);

      expect(SecondaryTitleTimeline.isComplete(total - 0.05, glyphs), isFalse);
      expect(SecondaryTitleTimeline.isComplete(total, glyphs), isTrue);

      // The last glyph starts latest, so the line cannot be done before it.
      expect(total, greaterThan(SecondaryTitleTimeline.startOf(glyphs - 1)));
    });

    test('an empty line completes immediately rather than hanging', () {
      expect(SecondaryTitleTimeline.durationFor(0), 0);
      expect(SecondaryTitleTimeline.isComplete(0, 0), isTrue);
    });
  });
}
