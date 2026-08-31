import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/data/audio/flame_app_audio.dart';
import 'package:portfolio/domain/audio/app_audio.dart';

/// How long an MP3 runs, read from the file itself.
///
/// Walks the frame headers and adds up their samples, which is exact for
/// both constant and variable bitrates — as opposed to dividing the file
/// size by a nominal bitrate, which is neither.
///
/// Here rather than in `lib` on purpose: nothing the app does needs to know
/// this. It exists so the durations the animations are timed from can be
/// checked against the sounds they claim to describe, instead of being four
/// numbers somebody measured once and nothing has looked at since.
Duration mp3Duration(File file) {
  const bitratesV1 = <int>[
    0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 0,
  ];
  const bitratesV2 = <int>[
    0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0,
  ];
  const rates = <int, List<int>>{
    3: <int>[44100, 48000, 32000], // MPEG 1
    2: <int>[22050, 24000, 16000], // MPEG 2
    0: <int>[11025, 12000, 8000], // MPEG 2.5
  };

  final bytes = file.readAsBytesSync();
  var i = 0;

  // An ID3v2 tag sits in front of the audio and its length is stored seven
  // bits to the byte, so that no length can contain a frame marker.
  if (bytes.length > 10 &&
      bytes[0] == 0x49 &&
      bytes[1] == 0x44 &&
      bytes[2] == 0x33) {
    i = 10 +
        ((bytes[6] & 0x7f) << 21 |
            (bytes[7] & 0x7f) << 14 |
            (bytes[8] & 0x7f) << 7 |
            (bytes[9] & 0x7f));
  }

  var seconds = 0.0;
  while (i + 4 <= bytes.length) {
    // Eleven set bits mark the start of a frame.
    if (bytes[i] != 0xFF || (bytes[i + 1] & 0xE0) != 0xE0) {
      i++;
      continue;
    }

    final version = (bytes[i + 1] >> 3) & 3;
    final layer = (bytes[i + 1] >> 1) & 3;
    final bitrateIndex = (bytes[i + 2] >> 4) & 15;
    final rateIndex = (bytes[i + 2] >> 2) & 3;
    final padding = (bytes[i + 2] >> 1) & 1;

    // Layer III only, and the reserved values are a false marker inside the
    // audio rather than a frame.
    if (layer != 1 ||
        rateIndex == 3 ||
        bitrateIndex == 0 ||
        bitrateIndex == 15 ||
        version == 1) {
      i++;
      continue;
    }

    final rate = rates[version]![rateIndex];
    final bitrate = (version == 3 ? bitratesV1 : bitratesV2)[bitrateIndex] * 1000;
    final samplesPerFrame = version == 3 ? 1152 : 576;
    final size = (samplesPerFrame ~/ 8) * bitrate ~/ rate + padding;
    if (size <= 0) {
      i++;
      continue;
    }

    seconds += samplesPerFrame / rate;
    i += size;
  }

  return Duration(milliseconds: (seconds * 1000).round());
}

void main() {
  group('a cue knows how long it runs', () {
    test('and it is how long the file runs', () {
      // Two animations are *timed from* these numbers rather than merely
      // described by them, so a swapped file desynchronises the app without
      // touching a line of code: the text would go on writing after the
      // typing had stopped, or stop while it carried on. This is the only
      // check that would notice.
      for (final cue in AudioCue.values) {
        final file = File('assets/audio/${FlameAppAudio.fileFor(cue)}');
        final actual = mp3Duration(file);

        expect(
          cue.length.inMilliseconds,
          closeTo(actual.inMilliseconds, 30),
          reason:
              '$cue says ${cue.length.inMilliseconds}ms but '
              '${file.path.split('/').last} runs ${actual.inMilliseconds}ms — '
              'anything timed from this cue is now out of step with it',
        );
      }
    });

    test('and the reader is measuring rather than guessing', () {
      // The walker above is the thing every other assertion here trusts. If
      // it silently returned zero, or the length of the file in bytes, the
      // group would pass on nonsense — so it is pinned to a sound whose
      // length was known independently before any of this was written.
      final file = File('assets/audio/${FlameAppAudio.fileFor(AudioCue.enter)}');
      expect(mp3Duration(file).inMilliseconds, closeTo(4056, 30));
    });
  });
}
