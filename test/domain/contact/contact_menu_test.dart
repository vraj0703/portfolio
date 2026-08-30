import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/audio/app_audio.dart';
import 'package:portfolio/domain/contact/contact_links.dart';
import 'package:portfolio/domain/contact/contact_menu.dart';
import 'package:portfolio/domain/contact/credits.dart';

void main() {
  group('ContactMenu', () {
    test('reads in the order it was asked for', () {
      expect(
        ContactMenu.entries.map((e) => e.destination),
        const <ContactDestination>[
          ContactDestination.gallery,
          ContactDestination.cv,
          ContactDestination.email,
          ContactDestination.github,
          ContactDestination.linkedin,
          ContactDestination.credits,
          ContactDestination.home,
        ],
      );
    });

    test('offers every destination exactly once', () {
      final seen = ContactMenu.entries.map((e) => e.destination).toSet();
      expect(seen.length, ContactMenu.entries.length);
      expect(seen.length, ContactDestination.values.length);
    });

    test('the gallery mark opens the row and the home mark closes it', () {
      // The two ways out of the contact screen bracket the four ways of
      // reaching Vishal, which is the whole arrangement: the words in the
      // middle are what the screen is for and the marks are the doors.
      expect(ContactMenu.entries.first.destination, ContactDestination.gallery);
      expect(ContactMenu.entries.last.destination, ContactDestination.home);
    });

    test('the heart sits immediately before home', () {
      final entries = ContactMenu.entries;
      final heart = entries.indexWhere(
        (e) => e.destination == ContactDestination.credits,
      );
      expect(heart, entries.length - 2);
    });

    test('only the three doorways are drawn as marks', () {
      final marks = ContactMenu.entries
          .where((e) => e.isMark)
          .map((e) => e.destination)
          .toSet();

      expect(marks, <ContactDestination>{
        ContactDestination.gallery,
        ContactDestination.credits,
        ContactDestination.home,
      });
    });

    test('every mark names a different drawing', () {
      final icons = ContactMenu.entries
          .where((e) => e.isMark)
          .map((e) => e.icon)
          .toSet();
      expect(icons.length, 3);
      expect(icons, ContactMenu.icons.toSet());
    });

    test('the two doorways say nothing, because the stage does', () {
      // The corridor raises its own arrival cue and the logo screen raises
      // its exit, so a press on either would be a second sound fighting the
      // first over one moment.
      expect(ContactMenu.cueFor(ContactDestination.gallery), isNull);
      expect(ContactMenu.cueFor(ContactDestination.home), isNull);
    });

    test('everything that leaves the page announces itself', () {
      // The four hand-offs to a browser. The click is the only sign the
      // visitor gets that the page heard them at all.
      for (final destination in <ContactDestination>[
        ContactDestination.cv,
        ContactDestination.email,
        ContactDestination.github,
        ContactDestination.linkedin,
      ]) {
        expect(ContactMenu.cueFor(destination), AudioCue.click);
      }
    });

    test('the heart steps in, and the dialog steps back out', () {
      // Neither a press nor a stage: it opens something over the screen and
      // closes it again. `CreditsDialog` answers this with `previous`, and
      // the pair is the point — either one alone is a control being pressed.
      expect(ContactMenu.cueFor(ContactDestination.credits), AudioCue.next);
    });

    test('every destination has been decided about', () {
      // A destination added without a thought for what it sounds like falls
      // through to silence, and silence is indistinguishable from a control
      // that did not work.
      for (final entry in ContactMenu.entries) {
        final decided =
            ContactMenu.cueFor(entry.destination) != null ||
            entry.destination == ContactDestination.gallery ||
            entry.destination == ContactDestination.home;
        expect(decided, isTrue, reason: '${entry.destination} is silent');
      }
    });

    test('the dot is punctuation, not an eighth destination', () {
      // It has to be shipped and tinted like the marks, but it is not one of
      // them — anything that treats `drawings` as the menu's entries would
      // put a circle in the row with nothing behind it.
      expect(ContactMenu.icons, isNot(contains(ContactMenu.separatorIcon)));
      expect(ContactMenu.drawings, contains(ContactMenu.separatorIcon));
      expect(ContactMenu.drawings, hasLength(ContactMenu.icons.length + 1));
    });

    test('every drawing is actually shipped', () async {
      TestWidgetsFlutterBinding.ensureInitialized();

      for (final icon in ContactMenu.drawings) {
        // The failure this catches is silent at runtime: an undeclared asset
        // does not throw where it is declared, it throws where it is drawn —
        // on the contact screen, in front of the visitor.
        final data = await rootBundle.loadString(icon);
        expect(data, contains('<svg'), reason: '$icon is not an SVG');
      }
    });
  });

  group('ContactProfile', () {
    test('points at the profiles that were asked for', () {
      expect(ContactProfile.vishal.github.toString(), contains('vraj0703'));
      expect(
        ContactProfile.vishal.linkedIn.toString(),
        contains('linkedin.com/in/vraj0703'),
      );
      expect(ContactProfile.vishal.email, contains('@'));
    });

    test('has no CV yet, and says so rather than pretending', () {
      // The one thing left to build. When the file is published this flips,
      // and nothing else in the menu, the screen or the launcher changes.
      expect(ContactProfile.vishal.hasCv, isFalse);
    });
  });

  group('Credits', () {
    test('credits something under every heading', () {
      expect(Credits.groups, isNotEmpty);
      for (final group in Credits.groups) {
        expect(group.heading, isNotEmpty);
        expect(group.items, isNotEmpty);
      }
    });
  });
}
