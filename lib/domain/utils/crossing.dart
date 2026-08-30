/// Fires once when a value passes a mark, and arms again when it comes back.
///
/// Two of the gallery's sounds hang off a scroll position rather than off a
/// tap: passing the arrow at the entrance, and the board beginning to rise.
/// Scroll position is not an event — it is a number reported every frame, and
/// the same number arrives sixty times a second while the visitor holds
/// still. Comparing it to a threshold in the render loop plays the cue sixty
/// times a second.
///
/// Rearming matters as much as firing. The corridor is scrollable in both
/// directions, so a visitor who scrolls back past the arrow and forward again
/// has genuinely passed it twice and should hear it twice — but a latch that
/// only ever fires once would go silent for the rest of the visit.
///
/// Pure, so both of those can be checked without a renderer.
class Crossing {
  Crossing({required this.at, this.rearmAt});

  /// The value the cue fires at, going up.
  final double at;

  /// The value it arms again at, coming back down.
  ///
  /// Below [at] by default, and deliberately allowed to differ: a threshold
  /// that arms at exactly the point it fires chatters, firing on every frame
  /// a visitor spends resting the scroll on the mark itself. The gap between
  /// the two is the hysteresis that stops it.
  final double? rearmAt;

  double get _rearm => rearmAt ?? at;

  bool _armed = true;

  /// Whether the cue is waiting to fire.
  bool get isArmed => _armed;

  /// Offers [value]. True exactly once per pass.
  bool crossed(double value) {
    if (_armed && value >= at) {
      _armed = false;
      return true;
    }

    if (!_armed && value < _rearm) _armed = true;
    return false;
  }

  /// Puts it back the way it started.
  void reset() => _armed = true;
}
