/// EXPERIMENT (cadence-experiment branch, not for merge): an even frame
/// cadence for a phone that cannot hold 60.
///
/// Warm, the ROG drew the gallery at ~40 fps with frames of two and three
/// ticks of its 120 Hz panel mixed, which reads as judder. Painting on every
/// 3rd tick only (an even 40) or every 4th (30) trades a little rate for an
/// even step. Asked every vsync tick whether to paint; the motion itself
/// advances by the real time since the last painted tick.
class FrameCadence {
  // -- The tuning, in one place. --------------------------------------------

  /// A painted frame "fits" its budget of [divisor] ticks with this slack.
  static const double slack = 1.15;

  /// Step down to a slower cadence when more than this share of the last
  /// second's painted frames overran the budget.
  static const double overrunShare = 0.10;

  /// Step back up only when this share of frames would have fit the faster
  /// budget, for [upHoldSeconds] in a row: hysteresis, so it does not flap.
  static const double fitShare = 0.95;
  static const double upHoldSeconds = 2;

  /// The slowest cadence: every 4th tick (30 fps on a 120 Hz panel).
  static const int maxDivisor = 4;

  // -- State. ------------------------------------------------------------------

  int _divisor = 2;
  bool _justPainted = false;
  double? _lastTickMs;
  double? _paintedAtMs;
  double _periodMs = 1000 / 120;
  final List<double> _recentIntervals = <double>[];
  final List<(double, double)> _costs = <(double, double)>[]; // (at, ms)
  double _fitSinceMs = -1;

  /// Every how many ticks a frame is painted now.
  int get divisor => _divisor;

  /// The panel's tick, as measured: the shortest tick interval seen lately.
  double get periodMs => _periodMs;

  /// Whether to paint the tick at [nowMs].
  bool tick(double nowMs) {
    final last = _lastTickMs;
    _lastTickMs = nowMs;
    if (last != null) {
      final interval = nowMs - last;
      if (interval > 2) {
        _recentIntervals.add(interval);
        if (_recentIntervals.length > 240) _recentIntervals.removeAt(0);
        var shortest = _recentIntervals.first;
        for (final i in _recentIntervals) {
          if (i < shortest) shortest = i;
        }
        _periodMs = shortest.clamp(6.0, 34.0);
      }
      // The tick after a painted one says what the paint cost.
      final painted = _paintedAtMs;
      if (painted != null && _justPainted) {
        _costs.add((nowMs, nowMs - painted));
      }
    }
    _justPainted = false;
    _costs.removeWhere((c) => nowMs - c.$1 > 1000);
    _govern(nowMs);

    // Time, not tick callbacks: a paint that takes longer than a tick has
    // already used up the ticks it spanned.
    final painted = _paintedAtMs;
    if (painted != null && nowMs - painted < (_divisor - 0.5) * _periodMs) {
      return false;
    }
    _paintedAtMs = nowMs;
    _justPainted = true;
    return true;
  }

  void _govern(double nowMs) {
    if (_costs.length < 10) return;
    final budget = _divisor * _periodMs * slack;
    final over = _costs.where((c) => c.$2 > budget).length / _costs.length;
    if (over > overrunShare && _divisor < maxDivisor) {
      _divisor++;
      _costs.clear();
      _fitSinceMs = -1;
      return;
    }
    if (_divisor > 1) {
      final faster = (_divisor - 1) * _periodMs * slack;
      final fit = _costs.where((c) => c.$2 <= faster).length / _costs.length;
      if (fit >= fitShare) {
        if (_fitSinceMs < 0) _fitSinceMs = nowMs;
        if (nowMs - _fitSinceMs >= upHoldSeconds * 1000) {
          _divisor--;
          _costs.clear();
          _fitSinceMs = -1;
        }
      } else {
        _fitSinceMs = -1;
      }
    }
  }
}
