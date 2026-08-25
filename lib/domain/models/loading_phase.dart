/// An independently-loading subsystem that the loading screen waits on.
///
/// Adding a phase is deliberately cheap: declare it here with a weight and
/// have the owning system report against it. Nothing else needs touching —
/// [LoadingProgress] normalises by the total weight, so weights do **not**
/// have to be rebalanced to keep summing to 1. A future gallery phase is
/// meant to be a one-line change:
///
/// ```dart
/// enum LoadingPhase {
///   game(weight: 1),
///   gallery(weight: 2);   // twice the bar, because it loads twice the work
/// }
/// ```
///
/// The weight is the share of the bar a phase occupies, relative to the other
/// phases. It should track roughly how long the phase actually takes, so the
/// bar advances at a believable rate rather than stalling on the slow one.
enum LoadingPhase {
  /// The Flame scene: engine boot, component construction, asset warm-up.
  game(weight: 1);

  const LoadingPhase({required this.weight});

  /// Relative share of the overall bar. Must be positive.
  final double weight;
}
