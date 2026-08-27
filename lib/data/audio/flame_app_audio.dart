import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:portfolio/domain/audio/app_audio.dart';

/// [AppAudio] backed by `flame_audio`.
///
/// Every call is wrapped: playback failures are logged in debug and swallowed
/// otherwise. On the web in particular, a browser will refuse to play until
/// the user has interacted with the page, and a scene that threw on that
/// would fail for a reason that has nothing to do with it.
///
/// Volumes live here rather than at the call sites. A cue's loudness is a
/// property of the sound, not of the moment that triggers it — putting it at
/// the call site means every new trigger has to rediscover the right number.
class FlameAppAudio implements AppAudio {
  FlameAppAudio();

  static const Map<AudioCue, String> _files = <AudioCue, String>{
    AudioCue.enter: 'enter_sound.mp3',
    AudioCue.titleLoaded: 'title_loaded.mp3',
    AudioCue.slideIn: 'slide_in.mp3',
    AudioCue.bouncyArrow: 'bouncy_arrow.mp3',
  };

  static const Map<AudioCue, double> _volumes = <AudioCue, double>{
    AudioCue.enter: 0.6,
    AudioCue.titleLoaded: 0.5,
    AudioCue.slideIn: 0.4,
    AudioCue.bouncyArrow: 0.35,
  };

  /// Shortest gap between two plays of the *same* cue.
  ///
  /// `FlameAudio.play` starts a fresh player per call, so a trigger the user
  /// can hammer — a button, a clickable arrow — stacks overlapping copies
  /// that sum into a much louder, muddier sound than the cue alone. Distinct
  /// cues are unaffected; this only collapses a repeat of the same one.
  static const Duration retriggerGuard = Duration(milliseconds: 120);

  final Stopwatch _clock = Stopwatch()..start();
  final Map<AudioCue, int> _lastPlayedMs = <AudioCue, int>{};

  bool _muted = false;
  bool _preloaded = false;

  @override
  bool get isMuted => _muted;

  @override
  Future<void> preload() async {
    if (_preloaded) return;
    _preloaded = true;

    try {
      await FlameAudio.audioCache.loadAll(_files.values.toList());
    } catch (error, stack) {
      // Not fatal: the first play will simply fetch instead.
      _report('preload failed', error, stack);
    }
  }

  @override
  void play(AudioCue cue, {double? volume}) {
    if (_muted) return;

    final file = _files[cue];
    if (file == null) return;

    if (!admit(cue)) return;

    // Deliberately not awaited. A cue marks a moment in an animation; making
    // the caller wait on the audio pipeline would couple the scene's timing
    // to how fast a file decodes.
    unawaited(_playSafely(file, volume ?? _volumes[cue] ?? 1.0));
  }

  /// Whether [cue] may sound now, recording the attempt if so.
  ///
  /// Separated from [play] so the guard can be tested for what it actually
  /// does. Folded into `play` it is unobservable without an audio backend,
  /// and a test could only assert that the constant exists — which would
  /// still pass with the guard deleted.
  @visibleForTesting
  bool admit(AudioCue cue) {
    final now = _clock.elapsedMilliseconds;
    final last = _lastPlayedMs[cue];
    if (last != null && now - last < retriggerGuard.inMilliseconds) {
      return false;
    }
    _lastPlayedMs[cue] = now;
    return true;
  }

  Future<void> _playSafely(String file, double volume) async {
    try {
      await FlameAudio.play(file, volume: volume);
    } catch (error, stack) {
      _report('play $file failed', error, stack);
    }
  }

  @override
  void setMuted(bool muted) => _muted = muted;

  @override
  Future<void> dispose() async {
    // Reset rather than just tearing down, so a disposed instance is still
    // usable. Nothing currently disposes this — it lives for the app — but a
    // half-dead object is a worse thing to leave behind than a reset one.
    _lastPlayedMs.clear();
    _preloaded = false;

    try {
      await FlameAudio.audioCache.clearAll();
    } catch (error, stack) {
      _report('dispose failed', error, stack);
    }
  }

  void _report(String message, Object error, StackTrace stack) {
    if (!kDebugMode) return;
    debugPrint('[audio] $message: $error');
  }
}
