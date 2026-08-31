import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/data/radio/streaming_radio.dart';
import 'package:portfolio/domain/radio/radio_player.dart';

void main() {
  group('a listener that arrives late is still told what is playing', () {
    test('the stream opens with the state, not with the next change', () async {
      // The bug this exists for, exactly: the radio goes on air while the
      // gallery scene is still warming up, and the wall only subscribes once
      // it has. On a plain broadcast stream that transition is gone by then,
      // so the face keeps what it was baked with — PLAY over a radio that is
      // playing, OFF over one that is on air, and a station name that does
      // not follow the dial.
      final radio = StreamingRadio();
      addTearDown(radio.dispose);

      await radio.play();
      expect(radio.state.isPlaying, isTrue, reason: 'nothing to be late for');

      // Subscribing only now — after everything has already happened.
      final first = await radio.changes.first;

      expect(
        first.status,
        radio.state.status,
        reason: 'the wall would have been lettered with a stale state',
      );
    });

    test('and goes on reporting changes after that opening one', () async {
      // The opening value must not cost the subscription its actual job.
      final radio = StreamingRadio();
      addTearDown(radio.dispose);

      final seen = <RadioStatus>[];
      final sub = radio.changes.listen((state) => seen.add(state.status));

      // Let the opening value land before moving the radio on.
      await Future<void>.delayed(Duration.zero);
      await radio.play();
      await Future<void>.delayed(Duration.zero);
      await radio.stop();
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();

      expect(seen.first, RadioStatus.off, reason: 'it did not open with now');
      expect(
        seen,
        containsAllInOrder(<RadioStatus>[RadioStatus.off, RadioStatus.onAir]),
        reason: 'the opening value replaced the changes instead of preceding them',
      );
      expect(seen.last, RadioStatus.off);
    });

    test('two listeners each get their own opening value', () async {
      // Two faces hang on one radio. A late-arriving second listener must be
      // told the state too, not just the first one to have asked.
      final radio = StreamingRadio();
      addTearDown(radio.dispose);

      await radio.play();

      expect((await radio.changes.first).isPlaying, isTrue);
      expect((await radio.changes.first).isPlaying, isTrue);
    });

    test('and cancelling one does not silence the other', () async {
      final radio = StreamingRadio();
      addTearDown(radio.dispose);

      final kept = <RadioStatus>[];
      final a = radio.changes.listen((s) => kept.add(s.status));
      final b = radio.changes.listen((_) {});
      await Future<void>.delayed(Duration.zero);

      await b.cancel();
      await radio.play();
      await Future<void>.delayed(Duration.zero);
      await a.cancel();

      expect(kept, contains(RadioStatus.onAir));
    });
  });
}
