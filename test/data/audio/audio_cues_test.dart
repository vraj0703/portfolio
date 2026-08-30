import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/audio/app_audio.dart';
import 'package:portfolio/data/audio/flame_app_audio.dart';

void main() {
  group('every cue can actually be heard', () {
    test('names a file', () {
      // A cue with no file behind it is silent and says nothing about it —
      // `play` finds nothing in the map and returns. The scene goes on
      // working, which is exactly why nobody notices.
      for (final cue in AudioCue.values) {
        expect(
          FlameAppAudio.fileFor(cue),
          isNotNull,
          reason: '$cue has no sound behind it',
        );
      }
    });

    test('and that file is shipped', () {
      for (final cue in AudioCue.values) {
        final file = File('assets/audio/${FlameAppAudio.fileFor(cue)}');
        expect(
          file.existsSync(),
          isTrue,
          reason: '$cue names ${FlameAppAudio.fileFor(cue)}, which is missing',
        );
      }
    });

    test('at a volume somebody chose', () {
      for (final cue in AudioCue.values) {
        final volume = FlameAppAudio.volumeFor(cue);
        expect(volume, isNotNull, reason: '$cue has no volume');
        expect(volume, greaterThan(0), reason: '$cue is silent');
        expect(volume, lessThanOrEqualTo(1), reason: '$cue clips');
      }
    });
  });

  group('the presses sit under the scene', () {
    test('a confirmation is quieter than the moment it interrupts', () {
      // These fire on every press, over whatever the scene is already
      // playing. Level with the music they stop reading as confirmation and
      // start reading as noise.
      const presses = <AudioCue>[
        AudioCue.click,
        AudioCue.keyStroke,
        AudioCue.previous,
        AudioCue.next,
        AudioCue.close,
      ];

      for (final press in presses) {
        expect(
          FlameAppAudio.volumeFor(press)!,
          lessThan(FlameAppAudio.volumeFor(AudioCue.enter)!),
          reason: '$press is louder than the scene it plays over',
        );
      }
    });
  });
}
