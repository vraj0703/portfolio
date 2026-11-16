import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/analytics/analytics.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';

import '../../support/scene_harness.dart';

class _Sent implements Analytics {
  final List<(String, Map<String, Object?>)> sent =
      <(String, Map<String, Object?>)>[];

  @override
  void capture(String event, Map<String, Object?> properties,
          {bool beforeUnload = false}) =>
      sent.add((event, properties));

  @override
  void screen(String path, Map<String, Object?> properties) {}

  @override
  bool flag(String key, {required bool orElse}) => orElse;

  @override
  Listenable get flagsChanged => ChangeNotifier();

  @override
  void captureException(Object error, StackTrace? stack) {}
}

/// Mute lives in the scene's state: one event, one field on every state,
/// seeded from the audio backend (Vishal's review of PR 1).
void main() {
  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 5));

  test('one event silences the site, and the state says so', () async {
    final audio = RecordingAudio();
    final bloc = SceneBloc(audio: audio);
    addTearDown(bloc.close);
    expect(bloc.state.muted, isFalse);

    bloc.add(const SceneEvent.muteToggled());
    await settle();
    expect(bloc.state.muted, isTrue);
    expect(audio.isMuted, isTrue);

    bloc.add(const SceneEvent.muteToggled());
    await settle();
    expect(bloc.state.muted, isFalse);
    expect(audio.isMuted, isFalse);
  });

  test('carried by every state, whichever handler builds it', () async {
    final bloc = SceneBloc(audio: RecordingAudio());
    addTearDown(bloc.close);
    bloc.add(const SceneEvent.muteToggled());
    await settle();
    // Every stage the visitor can reach, emitted afresh.
    for (final next in <SceneState>[
      const SceneState.logo(),
      const SceneState.title(),
      const SceneState.active(),
      const SceneState.gallery(),
      const SceneState.contact(),
    ]) {
      bloc.emit(next);
      expect(bloc.state.muted, isTrue, reason: '$next');
    }
  });

  test('seeded from the audio backend: a remount keeps the silence', () async {
    final audio = RecordingAudio()..setMuted(true);
    final bloc = SceneBloc(audio: audio);
    addTearDown(bloc.close);
    expect(bloc.state.muted, isTrue);
  });

  test('the radio goes quiet with it', () async {
    final radio = _VolumeRadio();
    final bloc = SceneBloc(audio: RecordingAudio(), radio: radio);
    addTearDown(bloc.close);
    bloc.add(const SceneEvent.muteToggled());
    await settle();
    expect(radio.volume, 0);
  });

  test('sound_toggled is sent from the one place it happens', () async {
    final sink = _Sent();
    final bloc = SceneBloc(
      audio: RecordingAudio(),
      events: SiteEvents(sink, viewport: () => (1280, 800)),
    );
    addTearDown(bloc.close);
    bloc.add(const SceneEvent.muteToggled());
    await settle();
    expect(sink.sent.single.$1, 'sound_toggled');
    expect(sink.sent.single.$2['muted'], isTrue);
  });
}

class _VolumeRadio extends RecordingRadio {
  double? volume;

  @override
  Future<void> setVolume(double volume) async => this.volume = volume;
}
