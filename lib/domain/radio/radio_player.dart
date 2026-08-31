import 'package:portfolio/domain/radio/radio_station.dart';

/// What the radio is doing.
enum RadioStatus {
  /// Silent, and not trying to be otherwise.
  off,

  /// Asked for, and waiting on somebody else's server.
  ///
  /// Its own state rather than a flavour of [off], because a stream can take
  /// several seconds to open and a control that looks unpressed for that long
  /// gets pressed again. The visitor is owed the difference between "you did
  /// not press it" and "it is coming".
  tuning,

  /// Playing.
  onAir,
}

/// Everything the wall needs to letter itself.
class RadioState {
  const RadioState({
    required this.status,
    required this.station,
    this.volume = defaultVolume,
    this.muted = false,
  });

  /// Quiet. It plays under a room the visitor came to look at, not over it.
  static const double defaultVolume = 0.25;

  final RadioStatus status;
  final int station;
  final double volume;
  final bool muted;

  RadioStation get tuned => RadioDial.at(station);

  bool get isPlaying => status == RadioStatus.onAir;
  bool get isTuning => status == RadioStatus.tuning;

  RadioState copyWith({
    RadioStatus? status,
    int? station,
    double? volume,
    bool? muted,
  }) => RadioState(
    status: status ?? this.status,
    station: station ?? this.station,
    volume: volume ?? this.volume,
    muted: muted ?? this.muted,
  );

  /// What the visitor should be told, given [status].
  ///
  /// Here rather than in the widget because it is the same three words
  /// wherever the radio is drawn, and because it is the only part of the
  /// radio's presentation that can be checked without a speaker.
  static const Map<RadioStatus, String> readouts = <RadioStatus, String>{
    RadioStatus.off: 'OFF',
    RadioStatus.tuning: 'TUNING',
    RadioStatus.onAir: 'ON AIR',
  };

  String get readout => readouts[status]!;

  @override
  bool operator ==(Object other) =>
      other is RadioState &&
      other.status == status &&
      other.station == station &&
      other.volume == volume &&
      other.muted == muted;

  @override
  int get hashCode => Object.hash(status, station, volume, muted);
}

/// The wall radio.
///
/// An interface, like [AppAudio] beside it, and for a sharper reason: this is
/// the only thing in the room that depends on a server nobody here runs. The
/// scene has to be able to draw a radio, and be tested drawing one, without a
/// network — and the day SomaFM changes a URL, exactly one class should have
/// to know.
///
/// Every implementation must treat playback as **best-effort**. A stream that
/// will not open, a browser refusing to play before the visitor has clicked
/// anything, a blocked mixed-content request: all ordinary, none worth
/// interrupting a gallery for. The radio goes quiet; the room does not stop.
abstract class RadioPlayer {
  /// What it is doing now.
  RadioState get state;

  /// Every change to that, so a widget can follow without polling.
  Stream<RadioState> get changes;

  /// Opens the current station. Returns when it is playing or has given up.
  Future<void> play();

  /// Closes the stream.
  ///
  /// Closes it, rather than pausing: a paused stream holds an open
  /// connection and goes on buffering audio nobody is listening to, which on
  /// a long visit is a steady leak for no benefit. There is nothing to
  /// resume from in live radio anyway — coming back means joining wherever
  /// it has got to.
  Future<void> stop();

  /// Steps to the next station, staying on air if it was.
  Future<void> next();

  Future<void> setVolume(double volume);

  Future<void> toggleMute();

  Future<void> dispose();
}

/// A [RadioPlayer] that does nothing.
///
/// The counterpart to `SilentAudio`, and it exists for the same reason: the
/// scene bloc drives the radio, and a test that walks the scene from loading
/// to the gallery should not have to stand up a streaming backend — or open
/// a connection to somebody else's server — to check where the camera ends
/// up.
///
/// Reports itself permanently off, which is true of it, so anything asking
/// whether the radio needs stopping gets the honest answer.
class SilentRadio implements RadioPlayer {
  const SilentRadio();

  @override
  RadioState get state =>
      const RadioState(status: RadioStatus.off, station: RadioDial.first);

  @override
  Stream<RadioState> get changes => const Stream<RadioState>.empty();

  @override
  Future<void> play() async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> next() async {}
  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> toggleMute() async {}
  @override
  Future<void> dispose() async {}
}
