import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/audio/app_audio.dart';
import 'package:portfolio/domain/config/logo_config.dart';

/// How long text spends writing itself, given the whole entrance and the
/// point in it where writing starts.
Duration writingWindow(Duration whole, double from) =>
    Duration(milliseconds: ((1 - from) * whole.inMilliseconds).round());

void main() {
  group('the typing and the sound of typing are one event', () {
    test('the contact menu writes for exactly as long as its cue', () {
      // The bigger of the two mismatches: the row wrote for 1320ms while its
      // cue ran 3600ms, so the typing carried on for nearly two seconds
      // after the menu had finished arriving.
      expect(
        writingWindow(
          LogoConfig.contactMenuDuration,
          LogoConfig.contactMenuTextStart,
        ).inMilliseconds,
        closeTo(AudioCue.keyboardTyping.length.inMilliseconds, 5),
      );
    });

    test('the menu cue is fired at the moment the row starts writing', () {
      // The tween decides when the first letter lands, as a fraction; the
      // timer decides when the first keystroke sounds, as a clock. Nothing
      // in the language holds those two to each other, so this does. Drift
      // here is a sound that starts before or after its own writing.
      expect(
        LogoConfig.contactMenuLead.inMilliseconds,
        closeTo(
          LogoConfig.contactMenuTextStart *
              LogoConfig.contactMenuDuration.inMilliseconds,
          1,
        ),
      );
    });

    test('the row still waits long enough for the mark to arrive', () {
      // The lead is not free to shrink to fit the sound: the menu types
      // under a mark that is still travelling in from the hall, and writing
      // that starts before it lands reads as two screens at once.
      expect(
        LogoConfig.contactMenuLead,
        greaterThanOrEqualTo(const Duration(milliseconds: 800)),
      );
    });

    test('the affordance still fades and draws its lines before writing', () {
      // It has no cue of its own any more, but the order it types in is
      // still the thing the menu's rule is shared with: fade, then lines,
      // then text.
      expect(LogoConfig.textStart, greaterThan(LogoConfig.linesStart));
      expect(LogoConfig.typedAt(LogoConfig.linesStart), 0);
      expect(LogoConfig.typedAt(LogoConfig.textStart), 0);
      expect(LogoConfig.typedAt(1), 1);
    });

    test('and the menu reads the same rule from a different start', () {
      // One animation with two entry points, not two animations. The menu
      // has nothing to write at its own lead and everything by the end.
      const from = LogoConfig.contactMenuTextStart;
      expect(LogoConfig.typedAt(from, from: from), 0);
      expect(LogoConfig.typedAt(1, from: from), 1);
      expect(LogoConfig.typedAt(from + (1 - from) / 2, from: from),
          closeTo(0.5, 0.001));
    });
  });
}
