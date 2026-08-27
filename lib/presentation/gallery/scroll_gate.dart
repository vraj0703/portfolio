/// Ignores the tail of a gesture that began before this surface existed.
///
/// When one scrolling stage hands over to another, the gesture does not stop
/// at the boundary. A wheel keeps emitting, and a trackpad flick keeps
/// coasting, for a good fraction of a second — so the new surface receives a
/// stream of input the visitor never aimed at it and starts already moving.
///
/// A fixed delay does not solve this: a long, deliberate scroll simply
/// outlasts it and leaks anyway. What actually separates the old gesture from
/// a new one is a **pause** — so this waits for the input to go quiet, and
/// arms on the first event after it does.
///
/// That also handles arriving *without* scrolling: with no events to wait
/// through, the quiet period has already elapsed and the visitor's first
/// scroll is honoured immediately.
class ScrollGate {
  ScrollGate({this.quietPeriod = defaultQuietPeriod});

  /// How still the input must go before a new gesture is recognised.
  ///
  /// Long enough to outlast the momentum phase of a flick, short enough that
  /// a visitor who pauses and scrolls again is answered at once.
  static const Duration defaultQuietPeriod = Duration(milliseconds: 150);

  final Duration quietPeriod;

  int _lastActivityMs = 0;
  bool _armed = false;

  /// Whether the gate has stopped swallowing input.
  bool get isArmed => _armed;

  /// Marks the moment this surface appeared.
  ///
  /// Any gesture already in flight is treated as belonging to what came
  /// before, until it goes quiet.
  void arrive(int nowMs) {
    _lastActivityMs = nowMs;
    _armed = false;
  }

  /// Whether a scroll event at [nowMs] should be acted on.
  ///
  /// Every event advances the activity clock, including the ones this
  /// swallows — otherwise a continuous stream would appear to be a pause
  /// simply because none of it was accepted.
  bool accept(int nowMs) {
    final wasQuiet = nowMs - _lastActivityMs >= quietPeriod.inMilliseconds;
    _lastActivityMs = nowMs;

    if (_armed) return true;
    if (!wasQuiet) return false;

    _armed = true;
    return true;
  }
}
