import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/data/di/dependency_manager.dart';
import 'package:portfolio/data/di/injection.dart';
import 'package:portfolio/domain/audio/app_audio.dart';
import 'package:portfolio/main.dart';

/// Records what it was asked to play, so a test can assert on sound without
/// standing up an audio backend.
class _RecordingAudio implements AppAudio {
  final List<AudioCue> played = <AudioCue>[];
  bool muted = false;
  int preloads = 0;

  @override
  Future<void> preload() async => preloads++;

  @override
  void play(AudioCue cue, {double? volume}) => played.add(cue);

  final List<double> scrubbed = <double>[];

  @override
  void scrub(AudioCue cue, double progress, {double? volume}) =>
      scrubbed.add(progress);

  @override
  void stopScrub(AudioCue cue) {}

  @override
  void setMuted(bool value) => muted = value;

  @override
  bool get isMuted => muted;

  @override
  Future<void> dispose() async {}
}

Future<AppAudio> resolveAudio(WidgetTester tester, {AppAudio? provide}) async {
  late AppAudio resolved;

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark().copyWith(
        extensions: <ThemeExtension<dynamic>>[
          if (provide != null) AppAudioExtension(audio: provide),
        ],
      ),
      home: Builder(
        builder: (context) {
          resolved = context.audio;
          return const SizedBox.shrink();
        },
      ),
    ),
  );

  return resolved;
}

void main() {
  group('context.audio', () {
    testWidgets('resolves whatever the theme provides', (tester) async {
      final recorder = _RecordingAudio();
      final resolved = await resolveAudio(tester, provide: recorder);

      expect(identical(resolved, recorder), isTrue);
    });

    testWidgets('falls back to silence when nothing is installed', (
      tester,
    ) async {
      // A widget test rendering part of the scene should not have to stand up
      // an audio backend, so the miss has to be survivable rather than throw.
      final resolved = await resolveAudio(tester);

      expect(resolved, isA<SilentAudio>());
      expect(() => resolved.play(AudioCue.enter), returnsNormally);
    });

    testWidgets('does not allocate a new fallback on every read', (
      tester,
    ) async {
      final first = await resolveAudio(tester);
      final second = await resolveAudio(tester);

      // const, so reads are free. Worth pinning: `context.audio` can be
      // called from a build method, and an allocation there is per frame.
      expect(identical(first, second), isTrue);
    });
  });

  group('AppAudioExtension', () {
    test('copyWith replaces the backend', () {
      final first = _RecordingAudio();
      final second = _RecordingAudio();

      final extension = AppAudioExtension(audio: first);
      expect(extension.copyWith(audio: second).audio, same(second));
      expect(extension.copyWith().audio, same(first));
    });

    test('lerp switches rather than blending', () {
      // A service cannot be interpolated; snapping at the midpoint is the
      // only sane behaviour, and silently returning a half-built one would
      // be worse.
      final from = AppAudioExtension(audio: _RecordingAudio());
      final to = AppAudioExtension(audio: _RecordingAudio());

      expect(from.lerp(to, 0).audio, same(from.audio));
      expect(from.lerp(to, 0.9).audio, same(to.audio));
      expect(from.lerp(null, 0.9).audio, same(from.audio));
    });
  });

  group('MyApp', () {
    setUp(() async {
      DependencyManager.instance.reset();
      await initDependencies();
    });

    tearDown(() => DependencyManager.instance.reset());

    testWidgets('installs a real audio backend, not the fallback', (
      tester,
    ) async {
      // Guards a one-line regression that is otherwise invisible: drop the
      // extension from MyApp and the app simply goes quiet, which looks
      // exactly like being muted, blocked by the browser, or missing a file.
      await tester.pumpWidget(const MyApp());
      await tester.pump();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final installed = app.theme?.extension<AppAudioExtension>();

      expect(installed, isNotNull, reason: 'MyApp must install audio');
      expect(installed!.audio, isNot(isA<SilentAudio>()));

      // Let the scene finish loading so nothing is pending at teardown.
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
