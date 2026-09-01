import 'package:flutter/material.dart';

/// The sounds the scene can play.
///
/// Cues are named for the moment they mark, not for the file behind them, so
/// swapping the sound for a beat never touches a call site.
///
/// Every cue's measured length is on [AudioCueLength.length]. It used to be
/// a list in this comment, and it is data now because two animations are
/// *timed from* it rather than merely checked against it — see
/// `LogoConfig.entranceDuration`. A comment cannot be read by the thing it
/// describes, and a sound that runs materially longer or shorter than the
/// motion it accompanies reads as a fault even when both are fine alone.
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

  /// The swell under the bold-text stage.
  ///
  /// Scrubbed rather than played: it is tied to scroll position, so the user
  /// hears the same point in the sound wherever they are in the sequence, and
  /// hears it run backwards if they scroll back. See [AppAudio.scrub].
  boldTextSwell,

  /// The moment the bold text resolves.
  ting,

  /// Any deliberate press: a frame, a sign, a destination on the contact
  /// menu, the arrow at the foot of the title.
  ///
  /// One cue for all of them on purpose. A press is a press, and giving each
  /// control its own voice makes an interface sound like a xylophone —
  /// what the ear learns instead is that this sound means "that worked".
  click,

  /// The corridor's own controls, which are the exception: stepping back,
  /// stepping on, and closing. Direction is the whole meaning of those
  /// three, and a single click throws it away.
  previous,
  next,
  close,

  /// The skills board rising into the hall.
  keyboardEntry,

  /// One keycap pressed.
  keyStroke,

  /// The contact menu's row typing itself on.
  ///
  /// The affordance under the mark had one of these too, and it is gone: it
  /// was the only cue in the app that fired before the visitor had clicked
  /// anything, which is the one thing a browser will not play. It was silent
  /// on arrival and audible only on a later visit to the same screen, and a
  /// sound that comes and goes by route is worse than no sound.
  keyboardTyping,

  /// Arriving in the corridor, by whichever route.
  ///
  /// Bound to the *state* rather than to the controls that reach it, because
  /// there are two ways in — scrolling through the bold text, and the
  /// gallery mark on the contact menu — and a room should not sound
  /// different depending on which door was used.
  galleryEntry,

  /// The corridor catching the visitor at the far wall.
  ///
  /// Marks the scroll being claimed rather than the camera arriving: the two
  /// are a moment apart, and the sound belongs with the deceleration, which
  /// is the part that reads as being taken hold of.
  snap,

  /// Leaving one section of the site for another.
  ///
  /// The two signs cut into the marble. A press is a press everywhere else,
  /// but these two do not act on the room the visitor is standing in — they
  /// put it away and open something else, and that is a larger thing than a
  /// click can say.
  pageTurn,
}

/// How long the file behind each cue runs.
///
/// Measured from the assets themselves, and kept as data because animation
/// timings are derived from it: the affordance and the contact menu each type
/// for exactly as long as the sound of them being typed. Anything that reads
/// one of these is asserting that a motion and a sound are *one event*, not
/// two that happen to overlap.
///
/// Exhaustive on purpose. A new cue will not compile until its length is
/// measured, which is the only reliable moment to do it.
extension AudioCueLength on AudioCue {
  Duration get length => switch (this) {
    AudioCue.enter => const Duration(milliseconds: 4056),
    AudioCue.titleLoaded => const Duration(milliseconds: 4624),
    AudioCue.slideIn => const Duration(milliseconds: 2064),
    AudioCue.bouncyArrow => const Duration(milliseconds: 1320),
    AudioCue.boldTextSwell => const Duration(milliseconds: 3624),
    AudioCue.ting => const Duration(milliseconds: 836),
    AudioCue.click => const Duration(milliseconds: 696),
    AudioCue.previous => const Duration(milliseconds: 784),
    AudioCue.next => const Duration(milliseconds: 784),
    AudioCue.close => const Duration(milliseconds: 1296),
    AudioCue.keyboardEntry => const Duration(milliseconds: 2544),
    AudioCue.keyStroke => const Duration(milliseconds: 1032),
    AudioCue.keyboardTyping => const Duration(milliseconds: 3600),
    AudioCue.galleryEntry => const Duration(milliseconds: 2280),
    AudioCue.snap => const Duration(milliseconds: 888),
    AudioCue.pageTurn => const Duration(milliseconds: 1056),
  };
}

/// How much of a cue sounds *after* the last thing in it happens.
///
/// Silence and decay at the end of a file. Irrelevant to playing one, and
/// decisive for anything timed against it: an animation matched to the whole
/// length finishes into the tail, so its last step lands after the last thing
/// anybody hears and reads as lag.
///
/// Measured by decoding the file and walking back from the end to the last
/// point it rises above a fraction of its own peak — the answer was the same
/// at every threshold from 2% to 20% of peak, which is what a hard stop
/// followed by silence looks like.
extension AudioCueTail on AudioCue {
  Duration get tail => switch (this) {
    // 22 keystrokes, the last at 3000ms of 3600.
    AudioCue.keyboardTyping => const Duration(milliseconds: 600),
    _ => Duration.zero,
  };

  /// How long the cue runs up to its last event.
  Duration get sounding => length - tail;
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

  /// Holds [cue] at [progress] (`0..1`) through its own length.
  ///
  /// For sound bound to a gesture rather than to a moment: scrolling forward
  /// walks into the sound, scrolling back walks out of it. [volume] is
  /// usually derived from how fast the user is moving, so a slow scroll is
  /// quiet and a fast one swells.
  ///
  /// Implementations should throttle: seeking a decoder every frame stutters,
  /// and the ear cannot hear the difference.
  void scrub(AudioCue cue, double progress, {double? volume});

  /// Stops a cue started by [scrub].
  void stopScrub(AudioCue cue);

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
