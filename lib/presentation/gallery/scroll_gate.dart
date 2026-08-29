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
///
/// The gate only works if it is offered *every* event from the moment the
/// surface appears. Leave it blind for even a few frames — behind a
/// placeholder, say — and the tail flows past unseen, so the first event it
/// does get looks like the pause it was waiting for.
class ScrollGate {
  ScrollGate({
    this.quietPeriod = defaultQuietPeriod,
    this.maximumHold = defaultMaximumHold,
  });

  /// How still the input must go before a new gesture is recognised.
  ///
  /// Deliberately longer than the gap between momentum events. A coasting
  /// trackpad does not emit evenly: its events *spread out* as it decelerates,
  /// so a short threshold is satisfied by the tail of the very gesture it is
  /// supposed to exclude, and the gate arms mid-coast.
  static const Duration defaultQuietPeriod = Duration(milliseconds: 350);

  /// How long the gate may swallow input before it gives up and arms.
  ///
  /// Without a bound the gate is a trap. It opens only on a pause, and a
  /// visitor who scrolls and sees nothing happen does not pause — they scroll
  /// harder, which is exactly what keeps it shut. Reaching the corridor a
  /// second time made that plain: the gallery was unscrollable until the
  /// visitor happened to click something, because clicking was the only thing
  /// that produced the stillness the gate wanted.
  ///
  /// The bound is not a compromise on the original problem, it is the honest
  /// end of it. The gate exists to disown the tail of the gesture that
  /// carried the visitor here, and a second after the handover there is no
  /// tail left — anything still arriving is someone asking to move, and the
  /// right answer to that is to move.
  static const Duration defaultMaximumHold = Duration(milliseconds: 1200);

  final Duration quietPeriod;
  final Duration maximumHold;

  int _arrivedAtMs = 0;
  int _lastActivityMs = 0;
  bool _armed = false;

  /// Whether the gate has stopped swallowing input.
  bool get isArmed => _armed;

  /// Marks the moment this surface appeared.
  ///
  /// Any gesture already in flight is treated as belonging to what came
  /// before, until it goes quiet.
  void arrive(int nowMs) {
    _arrivedAtMs = nowMs;
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
    final heldLongEnough =
        nowMs - _arrivedAtMs >= maximumHold.inMilliseconds;
    _lastActivityMs = nowMs;

    if (_armed) return true;
    if (!wasQuiet && !heldLongEnough) return false;

    _armed = true;
    return true;
  }
}
