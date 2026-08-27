import 'package:flutter/material.dart';

/// The sounds the scene can play.
///
/// Cues are named for the moment they mark, not for the file behind them, so
/// swapping the sound for a beat never touches a call site.
///
/// Measured lengths of the current files, for anyone aligning an animation to
/// one — a cue that runs materially longer or shorter than the motion it
/// accompanies reads as a mistake even when both are individually fine:
///
///  * [enter] — 4.06s
///  * [titleLoaded] — 4.62s
///  * [slideIn] — 2.06s
///  * [bouncyArrow] — 1.32s
enum AudioCue {
  /// The user commits: the mark dismissed, the scene opening up.
  enter,

  /// The hero title resolving.
  ///
  /// Fired when the name *starts resolving*, not when the title stage is
  /// entered — the stage opens on a two-second pause, so a cue hung off the
  /// state change would play to an empty screen.
  titleLoaded,

  /// The line beneath the title sliding in.
  slideIn,

  /// The scroll affordance arriving once the title has settled.
  bouncyArrow,
}

/// Contract for the app's sound.
///
/// Mirrors how colour and copy are handled: the scene depends on this
/// abstraction rather than on an audio package, so the backend can change —
/// or be stubbed out entirely in tests — without touching anything that makes
/// a sound.
///
/// Implementations must treat playback as **best-effort**. A missing file, a
/// codec the platform dislikes, or a browser refusing to play before the user
/// has interacted are all normal conditions, and none of them are worth
/// interrupting the scene for. Sound is decoration here; the scene runs
/// silently rather than not at all.
abstract class AppAudio {
  /// Warms the cache so the first cue is not late.
  ///
  /// Safe to call more than once, and safe to ignore the result — a failure
  /// here just means the first play has to fetch.
  Future<void> preload();

  /// Plays [cue], if sound is on and the asset is available.
  void play(AudioCue cue, {double? volume});

  /// Silences everything without unloading it.
  void setMuted(bool muted);

  bool get isMuted;

  /// Releases players and cached data.
  Future<void> dispose();
}

/// [AppAudioExtension] allows the custom audio service to be part of the
/// Flutter [ThemeData]. This follows the **Open/Closed Principle (OCP)**,
/// allowing the theme to be extended with new capabilities.
class AppAudioExtension extends ThemeExtension<AppAudioExtension> {
  final AppAudio audio;

  const AppAudioExtension({required this.audio});

  @override
  AppAudioExtension copyWith({AppAudio? audio}) {
    return AppAudioExtension(audio: audio ?? this.audio);
  }

  @override
  AppAudioExtension lerp(ThemeExtension<AppAudioExtension>? other, double t) {
    if (other is! AppAudioExtension) return this;
    // Audio services don't lerp; we keep the current one.
    return t < 0.5 ? this : other;
  }
}

/// Extension on [BuildContext] for easy and type-safe access to [AppAudio].
/// This adheres to the **Interface Segregation Principle (ISP)** by providing
/// a dedicated API for audio.
extension AudioX on BuildContext {
  AppAudio get audio =>
      Theme.of(this).extension<AppAudioExtension>()?.audio ?? const SilentAudio();
}

/// An [AppAudio] that does nothing.
///
/// Used as the fallback when no [AppAudioExtension] is installed, which is
/// the normal case in a widget test — a test that renders part of the scene
/// should not have to stand up an audio backend to do it.
///
/// Public and `const` on purpose. Public so a test can pass it deliberately
/// rather than relying on the fallback by accident, and `const` so resolving
/// it does not allocate on every read.
class SilentAudio implements AppAudio {
  const SilentAudio();

  @override
  Future<void> preload() async {}
  @override
  void play(AudioCue cue, {double? volume}) {}
  @override
  void setMuted(bool muted) {}
  @override
  bool get isMuted => false;
  @override
  Future<void> dispose() async {}
}
