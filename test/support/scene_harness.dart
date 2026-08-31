import 'dart:async';

import 'package:portfolio/domain/audio/app_audio.dart';
import 'package:portfolio/domain/radio/radio_player.dart';
import 'package:portfolio/domain/radio/radio_station.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/domain/style/scene_palette.dart';
import 'package:portfolio/domain/style/strings.dart';
import 'package:portfolio/domain/style/text_styles.dart';

/// The palette the scene is built with in tests.
///
/// Shared for the same reason the walk-through in `scene_journey` is: it
/// enumerates every field `ScenePalette` has, so a second copy does not fail
/// when one is added — it goes on testing a scene built from stale values.
ScenePalette scenePalette() {
  const colors = DefaultAppColors();
  const strings = DefaultAppStrings();
  const type = DefaultAppTypography();

  return ScenePalette(
    background: colors.sceneBackground,
    overlayText: colors.logoOverlayText,
    overlayTextShadow: colors.logoOverlayTextShadow,
    lineGradient: colors.logoLineGradient,
    lineStops: colors.logoLineStops,
    enterStyle: type.enter,
    tapToEnter: strings.tapToEnter,
    primaryTitle: strings.primaryTitle,
    secondaryTitle: strings.secondaryTitle,
    titlePrimaryStyle: type.titlePrimary,
    titleSecondaryStyle: type.titleSecondary,
    titleBase: colors.titleBase,
    scrollCue: colors.scrollCue,
    scrollCueShadow: colors.scrollCueShadow,
    contactDim: colors.contactDim,
    sceneVeil: colors.sceneVeil,
    boldText: strings.boldText,
    boldTextStyle: type.boldText,
  );
}

/// An [AppAudio] that keeps a tally instead of making a sound.
///
/// [SilentAudio] is the right default for a test that does not care what the
/// scene plays. This is for the ones that do — where the *moment* a cue fires
/// is the behaviour under test, not a side effect of it.
class RecordingAudio implements AppAudio {
  final List<AudioCue> played = <AudioCue>[];

  int timesPlayed(AudioCue cue) => played.where((c) => c == cue).length;

  @override
  void play(AudioCue cue, {double? volume}) => played.add(cue);

  @override
  Future<void> preload() async {}
  @override
  void scrub(AudioCue cue, double progress, {double? volume}) {}
  @override
  void stopScrub(AudioCue cue) {}
  @override
  void setMuted(bool muted) {}
  @override
  bool get isMuted => false;
  @override
  Future<void> dispose() async {}
}

/// A [RadioPlayer] that keeps a tally instead of opening a stream.
///
/// [SilentRadio] answers "off" and does nothing, which is right for a test
/// that does not care. This one remembers what it was asked to do and moves
/// its own state accordingly, so a test can check both that the radio was
/// started and that it was started *once*.
class RecordingRadio implements RadioPlayer {
  final List<String> calls = <String>[];

  final StreamController<RadioState> _changes =
      StreamController<RadioState>.broadcast();

  RadioState _state = const RadioState(
    status: RadioStatus.off,
    station: RadioDial.first,
  );

  @override
  RadioState get state => _state;

  @override
  Stream<RadioState> get changes => _changes.stream;

  void _moveTo(RadioStatus status) {
    _state = RadioState(status: status, station: _state.station);
    if (!_changes.isClosed) _changes.add(_state);
  }

  @override
  Future<void> play() async {
    calls.add('play');
    _moveTo(RadioStatus.onAir);
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
    _moveTo(RadioStatus.off);
  }

  @override
  Future<void> next() async => calls.add('next');

  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> toggleMute() async {}
  @override
  Future<void> dispose() async => _changes.close();
}
