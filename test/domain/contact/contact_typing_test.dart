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

  group('a mark waits for the words it belongs to', () {
    // "Made with ♥" is the one entry that is words *and* a mark: nine
    // characters and one more for the glyph, ten in all.
    const madeWith = 9;
    const weight = madeWith + ContactTyping.markWeight;

    test('the heart is not there while the words are still arriving', () {
      // The bug this exists for: the mark's opacity was the entry's whole
      // reveal, so the heart faded up across every letter and was visibly
      // on screen beside the "M" of "Made". The entry showed what it meant
      // before it had said it.
      for (final reveal in <double>[0.05, 0.25, 0.5, 0.75, 0.89]) {
        expect(
          ContactTyping.markOf(reveal: reveal, weight: weight),
          0,
          reason: 'the heart was $reveal of the way on at $reveal of the entry',
        );
      }
    });

    test('and arrives on the beat after the last letter', () {
      // The words finish at nine tenths, which is where the mark starts.
      expect(
        ContactTyping.lettersOf(
          reveal: madeWith / weight,
          weight: weight,
          letters: madeWith,
        ),
        madeWith,
        reason: 'the words were still unfinished when the mark began',
      );
      expect(ContactTyping.markOf(reveal: madeWith / weight, weight: weight), 0);
      expect(ContactTyping.markOf(reveal: 1, weight: weight), 1);
    });

    test('an entry that is only a mark has nothing to wait for', () {
      // The gallery and home marks carry no words, so their beat is the
      // entry's — and this must not push them to the end of a beat they
      // already own.
      const alone = ContactTyping.markWeight;
      expect(ContactTyping.markOf(reveal: 0, weight: alone), 0);
      expect(ContactTyping.markOf(reveal: 0.5, weight: alone), 0.5);
      expect(ContactTyping.markOf(reveal: 1, weight: alone), 1);
    });

    test('a word without a mark still types across its whole entry', () {
      // Every other entry: weight and letters are the same number, so this
      // has to behave exactly as counting characters did before.
      expect(
        ContactTyping.lettersOf(reveal: 0.5, weight: 8, letters: 8),
        4,
      );
      expect(ContactTyping.lettersOf(reveal: 0.01, weight: 8, letters: 8), 1,
          reason: 'the first letter waited for the whole of its own beat');
      expect(ContactTyping.lettersOf(reveal: 1, weight: 8, letters: 8), 8);
    });

    test('and no letter is dropped to make room for the mark', () {
      // The word shares its entry with the glyph, so measuring it against
      // its own length instead of the entry's would finish it a beat early
      // and leave the last letter waiting on the heart.
      for (var i = 0; i <= 10; i++) {
        final letters = ContactTyping.lettersOf(
          reveal: i / 10,
          weight: weight,
          letters: madeWith,
        );
        expect(letters, lessThanOrEqualTo(madeWith));
        expect(letters, greaterThanOrEqualTo(0));
      }
      expect(
        ContactTyping.lettersOf(reveal: 1, weight: weight, letters: madeWith),
        madeWith,
      );
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
