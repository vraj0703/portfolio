import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/config/logo_config.dart';
import 'package:portfolio/domain/contact/contact_typing.dart';

void main() {
  // Two long words either side of a mark, so a lopsided row is under test
  // rather than a tidy one.
  const weights = <int>[1, 2, 6, 6, 8, 10, 1];

  double reveal(int index, double typed) =>
      ContactTyping.revealOf(index: index, typed: typed, weights: weights);

  group('the row types left to right', () {
    test('nothing has arrived before it starts', () {
      for (var i = 0; i < weights.length; i++) {
        expect(reveal(i, 0), 0, reason: 'entry $i');
      }
    });

    test('everything has by the time it ends', () {
      for (var i = 0; i < weights.length; i++) {
        expect(reveal(i, 1), 1, reason: 'entry $i');
      }
    });

    test('and no entry runs ahead of the one before it', () {
      for (final typed in <double>[0.1, 0.25, 0.5, 0.75, 0.9]) {
        for (var i = 1; i < weights.length; i++) {
          expect(
            reveal(i, typed),
            lessThanOrEqualTo(reveal(i - 1, typed)),
            reason: 'entry $i overtook ${i - 1} at $typed',
          );
        }
      }
    });
  });

  group('a long word takes longer than a short one', () {
    test('because the pace is even, not the beat', () {
      // The whole difference between typing and a stagger. Given an equal
      // beat each, "cv" and "linkedin" would arrive at the same rate and the
      // row would read as items appearing rather than as a line being typed.
      // Thirty-four characters of entry, and a separator between each pair.
      const total = 34 + 6;
      expect(ContactTyping.totalWeight(weights), total);

      // One character into the row's second entry, which costs two: it
      // starts at 1 (the first entry) + 1 (a separator).
      expect(reveal(1, 3 / total), closeTo(0.5, 1e-9));

      // One character into the sixth, which costs ten — a tenth of the way
      // through, where the same one character finished half of the second.
      expect(reveal(5, 29 / total), closeTo(0.1, 1e-9));
    });
  });

  group('the punctuation waits for what it separates', () {
    test('and arrives only once that entry is whole', () {
      // A dot ahead of the word on its left is a bullet pointing at nothing.
      expect(
        ContactTyping.separatorAfter(index: 0, typed: 0.02, weights: weights),
        0,
      );
      expect(
        ContactTyping.separatorAfter(index: 0, typed: 1, weights: weights),
        1,
      );
    });
  });

  group('it is the affordance\'s animation, not a copy of it', () {
    test('both read the same rule for when typing starts', () {
      // `LogoConfig.typedAt` is what the label reads. If the menu had its own
      // curve the two would drift apart the moment either was retuned — and
      // they are meant to be one animation on two things, not two.
      expect(LogoConfig.typedAt(0), 0);
      expect(LogoConfig.typedAt(LogoConfig.textStart), 0);
      expect(LogoConfig.typedAt(1), 1);

      // Nothing types while the layer is still fading up.
      expect(LogoConfig.typedAt(LogoConfig.textStart / 2), 0);
      expect(LogoConfig.typedAt((1 + LogoConfig.textStart) / 2), closeTo(0.5, 1e-9));
    });
  });

  group('edges', () {
    test('an index off either end reveals nothing', () {
      expect(reveal(-1, 1), 0);
      expect(reveal(weights.length, 1), 0);
    });

    test('an empty row is finished before it begins', () {
      expect(ContactTyping.totalWeight(<int>[]), 0);
      expect(
        ContactTyping.revealOf(index: 0, typed: 0, weights: <int>[]),
        0,
      );
    });
  });
}
