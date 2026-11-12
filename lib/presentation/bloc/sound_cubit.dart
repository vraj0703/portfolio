import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:portfolio/domain/audio/app_audio.dart';
import 'package:portfolio/domain/radio/radio_player.dart';

/// Whether the site is silent.
///
/// A cubit rather than state on the control that flips it, so the control
/// can stay stateless: [AppAudio.isMuted] is a plain getter with nothing to
/// listen to, and a widget that reads it has no way to learn that it changed
/// except by holding a `setState` of its own. This holds the answer the
/// control renders and rebuilds it when it moves.
///
/// Seeded from the audio backend, not from `false`. The backend lives for
/// the whole visit and this lives for one mount of the scene, so a site
/// silenced before a remount must come back silent and say so.
class SoundCubit extends Cubit<bool> {
  SoundCubit({required AppAudio audio, required this._radio})
    : _audio = audio,
      super(audio.isMuted);

  final AppAudio _audio;
  final RadioPlayer _radio;

  /// Turns every sound in the site off, or on again.
  ///
  /// Both of them. The scene's cues and the wall radio are separate players,
  /// and a switch that silenced one while the other played on would not be a
  /// mute — it would be a volume control the visitor could not find.
  void toggle() {
    final silencing = !_audio.isMuted;

    // The confirmation plays before the silence, and not at all on the way
    // into it — a click swallowed by the thing it is confirming leaves the
    // press feeling unregistered.
    if (!silencing) _audio.play(AudioCue.click);

    _audio.setMuted(silencing);
    unawaited(_radio.setVolume(silencing ? 0 : RadioState.defaultVolume));

    emit(silencing);
  }
}
