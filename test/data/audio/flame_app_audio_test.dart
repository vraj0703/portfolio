import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/core/di/dependency_manager.dart';
import 'package:portfolio/core/di/injection.dart';
import 'package:portfolio/data/audio/flame_app_audio.dart';
import 'package:portfolio/domain/audio/app_audio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlameAppAudio', () {
    late AppAudio audio;

    setUp(() => audio = FlameAppAudio());

    test('starts unmuted', () {
      expect(audio.isMuted, isFalse);
    });

    test('mute is remembered', () {
      audio
        ..setMuted(true)
        ..setMuted(true);
      expect(audio.isMuted, isTrue);

      audio.setMuted(false);
      expect(audio.isMuted, isFalse);
    });

    test('playing never throws, even with no audio backend', () {
      // The whole point of the wrapper. In a test binding there is no
      // platform audio at all, and on the web a browser refuses to play
      // before the user has interacted — neither is a reason to take the
      // scene down.
      for (final cue in AudioCue.values) {
        expect(() => audio.play(cue), returnsNormally, reason: cue.name);
      }
    });

    test('playing while muted is a no-op that still does not throw', () {
      audio.setMuted(true);
      for (final cue in AudioCue.values) {
        expect(() => audio.play(cue), returnsNormally, reason: cue.name);
      }
    });

    test('collapses a hammered repeat of the same cue', () {
      // Each play starts its own player, so an unguarded spammable trigger —
      // a button, a clickable arrow — stacks copies that sum into something
      // much louder and muddier than the cue alone.
      final backend = audio as FlameAppAudio;

      expect(backend.admit(AudioCue.bouncyArrow), isTrue);
      expect(backend.admit(AudioCue.bouncyArrow), isFalse);
      expect(backend.admit(AudioCue.bouncyArrow), isFalse);
    });

    test('the guard does not silence a different cue', () {
      // Distinct cues overlap by design — the title's swell is still ringing
      // when the line slides in.
      final backend = audio as FlameAppAudio;

      expect(backend.admit(AudioCue.titleLoaded), isTrue);
      expect(backend.admit(AudioCue.slideIn), isTrue);
    });

    test('the same cue is allowed again once the guard has passed', () async {
      final backend = audio as FlameAppAudio;

      expect(backend.admit(AudioCue.enter), isTrue);
      await Future<void>.delayed(
        FlameAppAudio.retriggerGuard + const Duration(milliseconds: 30),
      );
      expect(backend.admit(AudioCue.enter), isTrue);
    });

    test('an explicit volume is accepted', () {
      expect(() => audio.play(AudioCue.enter, volume: 0.1), returnsNormally);
    });

    test('preload never throws and is safe to repeat', () async {
      await expectLater(audio.preload(), completes);
      await expectLater(audio.preload(), completes);
    });

    test('dispose never throws', () async {
      await expectLater(audio.dispose(), completes);
    });
  });

  group('registration', () {
    setUp(() async {
      DependencyManager.instance.reset();
      await initDependencies();
    });

    tearDown(() => DependencyManager.instance.reset());

    test('resolves through the container', () {
      expect(locate<AppAudio>(), isA<FlameAppAudio>());
    });

    test('is shared, because it owns a cache and a pool of players', () {
      // A second instance would duplicate both and let cues talk over one
      // another, so this must not be a factory.
      expect(identical(locate<AppAudio>(), locate<AppAudio>()), isTrue);
    });
  });
}
