import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:portfolio/data/radio/radio_stream.dart';
import 'package:portfolio/domain/radio/radio_player.dart';
import 'package:portfolio/domain/radio/radio_station.dart';

/// [RadioPlayer] over a live HTTP stream.
///
/// The stream itself is [RadioStream], which on the web is the browser's own
/// audio element rather than the package every other sound here goes through.
/// That is not a preference: `audioplayers` refuses a live SomaFM URL outright
/// with `MEDIA_ELEMENT_ERROR: Format error (Code: 4)`, because what it builds
/// expects a *file* — something with a length and an end — and a radio
/// station is neither.
///
/// Every call is wrapped. A stream that will not open, a browser refusing to
/// play before the visitor has clicked anything, a blocked request — all
/// ordinary conditions for something served from a machine nobody here owns,
/// and none of them worth an exception crossing a tap handler. The radio
/// falls silent and says so; the room carries on.
class StreamingRadio implements RadioPlayer {
  StreamingRadio();

  final StreamController<RadioState> _changes =
      StreamController<RadioState>.broadcast();

  final RadioStream _stream = BrowserRadioStream();

  RadioState _state = const RadioState(
    status: RadioStatus.off,
    station: RadioDial.first,
  );

  @override
  RadioState get state => _state;

  @override
  Stream<RadioState> get changes {
    late final StreamController<RadioState> opened;
    StreamSubscription<RadioState>? source;

    opened = StreamController<RadioState>(
      onListen: () {
        // Forwarding is set up *before* the current state goes out, so a
        // change arriving in between queues behind it rather than being lost
        // in front of it. The other order looks equivalent and drops events.
        source = _changes.stream.listen(opened.add, onError: opened.addError);
        opened.add(_state);
      },
      onCancel: () async => source?.cancel(),
    );

    return opened.stream;
  }

  void _emit(RadioState next) {
    if (next == _state) return;
    _state = next;
    if (!_changes.isClosed) _changes.add(next);
  }

  @override
  Future<void> play() async {
    if (_state.isPlaying || _state.isTuning) return;

    // Announced before the wait, not after. Opening a stream can take
    // several seconds, and a control that looks unpressed for that long gets
    // pressed again.
    _emit(_state.copyWith(status: RadioStatus.tuning));

    try {
      await _stream.open(
        _state.tuned.stream,
        volume: _state.muted ? 0 : _state.volume,
      );

      _emit(_state.copyWith(status: RadioStatus.onAir));
    } catch (error) {
      debugPrint('[radio] ${_state.tuned.name} would not open: $error');
      _emit(_state.copyWith(status: RadioStatus.off));
    }
  }

  @override
  Future<void> stop() async {
    // Released rather than paused. A paused stream holds its connection open
    // and goes on buffering audio nobody is listening to; there is nothing to
    // resume from in live radio anyway.
    _emit(_state.copyWith(status: RadioStatus.off));

    try {
      await _stream.close();
    } catch (error) {
      debugPrint('[radio] would not close cleanly: $error');
    }
  }

  @override
  Future<void> next() async {
    final wasOn = _state.isPlaying || _state.isTuning;

    await stop();
    _emit(_state.copyWith(station: RadioDial.next(_state.station)));

    // Only follows the visitor. Stepping the dial while it is off is reading
    // the label, not asking to listen — starting the sound there would be
    // the room deciding for them.
    if (wasOn) await play();
  }

  @override
  Future<void> setVolume(double volume) async {
    final level = volume.clamp(0.0, 1.0);

    // Turning it to nothing *is* muting it, and turning it up again is
    // unmuting: two controls for one idea otherwise, which is how a radio
    // ends up silent with its mute button off.
    _emit(_state.copyWith(volume: level, muted: level == 0));
    await _applyVolume();
  }

  @override
  Future<void> toggleMute() async {
    _emit(_state.copyWith(muted: !_state.muted));
    await _applyVolume();
  }

  Future<void> _applyVolume() async {
    try {
      await _stream.setVolume(_state.muted ? 0 : _state.volume);
    } catch (error) {
      debugPrint('[radio] volume would not take: $error');
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _changes.close();
  }
}
