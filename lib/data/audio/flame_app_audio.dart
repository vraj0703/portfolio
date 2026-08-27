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
    AudioCue.boldTextSwell: 'bold_text_swell.mp3',
    AudioCue.ting: 'ting.mp3',
  };

  static const Map<AudioCue, double> _volumes = <AudioCue, double>{
    AudioCue.enter: 0.6,
    AudioCue.titleLoaded: 0.5,
    AudioCue.slideIn: 0.4,
    AudioCue.bouncyArrow: 0.35,
    AudioCue.boldTextSwell: 0.6,
    AudioCue.ting: 0.45,
  };

  /// Shortest gap between two plays of the *same* cue.
  ///
  /// `FlameAudio.play` starts a fresh player per call, so a trigger the user
  /// can hammer — a button, a clickable arrow — stacks overlapping copies
  /// that sum into a much louder, muddier sound than the cue alone. Distinct
  /// cues are unaffected; this only collapses a repeat of the same one.
  static const Duration retriggerGuard = Duration(milliseconds: 120);

  /// Seeking a decoder on every frame stutters, and the ear cannot hear the
  /// difference — a scrubbed cue is re-aimed at roughly this rate instead.
  static const Duration scrubInterval = Duration(milliseconds: 90);

  final Stopwatch _clock = Stopwatch()..start();
  final Map<AudioCue, int> _lastPlayedMs = <AudioCue, int>{};

  final Map<AudioCue, AudioPlayer> _scrubPlayers = <AudioCue, AudioPlayer>{};
  final Map<AudioCue, Duration> _scrubLengths = <AudioCue, Duration>{};
  final Map<AudioCue, int> _lastScrubMs = <AudioCue, int>{};

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
  void scrub(AudioCue cue, double progress, {double? volume}) {
    if (_muted) return;

    final file = _files[cue];
    if (file == null) return;

    final now = _clock.elapsedMilliseconds;
    final last = _lastScrubMs[cue];
    if (last != null && now - last < scrubInterval.inMilliseconds) return;
    _lastScrubMs[cue] = now;

    unawaited(
      _scrubSafely(
        cue,
        file,
        progress.clamp(0.0, 1.0),
        volume ?? _volumes[cue] ?? 1.0,
      ),
    );
  }

  Future<void> _scrubSafely(
    AudioCue cue,
    String file,
    double progress,
    double volume,
  ) async {
    try {
      var player = _scrubPlayers[cue];
      if (player == null) {
        player = AudioPlayer();
        _scrubPlayers[cue] = player;
        await player.setSource(AssetSource('audio/\$file'));
        await player.setReleaseMode(ReleaseMode.stop);
        // Cached: asking the decoder for its length on every seek is a
        // round trip per frame for a number that never changes.
        _scrubLengths[cue] = await player.getDuration() ?? Duration.zero;
      }

      final length = _scrubLengths[cue] ?? Duration.zero;
      if (length == Duration.zero) return;

      await player.setVolume(volume.clamp(0.0, 1.0));
      if (player.state != PlayerState.playing) {
        await player.resume();
      }
      await player.seek(
        Duration(milliseconds: (length.inMilliseconds * progress).round()),
      );
    } catch (error, stack) {
      _report('scrub \$file failed', error, stack);
    }
  }

  @override
  void stopScrub(AudioCue cue) {
    final player = _scrubPlayers[cue];
    if (player == null) return;
    unawaited(player.stop().catchError((Object _) {}));
  }

  @override
  void setMuted(bool muted) => _muted = muted;

  @override
  Future<void> dispose() async {
    // Reset rather than just tearing down, so a disposed instance is still
    // usable. Nothing currently disposes this — it lives for the app — but a
    // half-dead object is a worse thing to leave behind than a reset one.
    _lastPlayedMs.clear();
    _lastScrubMs.clear();
    _scrubLengths.clear();
    _preloaded = false;

    for (final player in _scrubPlayers.values) {
      try {
        await player.dispose();
      } catch (_) {
        // A player that will not close is not worth failing teardown over.
      }
    }
    _scrubPlayers.clear();

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
