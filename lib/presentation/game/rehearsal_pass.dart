/// Marks the draws `MyGame.rehearseInto` makes through `RehearsalPixel`.
///
/// The scene's rule (`SceneState.rehearsesTitle`) says *whether* the title
/// stage rehearses; this says *which* draw is the rehearsal. Without it every
/// on-screen frame under the loading screen drew the title stage in full as
/// well, and loading doubled on the ROG (ms_ready ~25 s to ~57 s,
/// 2026-11-17). A component rehearses when both are true.
abstract final class RehearsalPass {
  /// True only while the rehearsal cast is being drawn into the pixel.
  static bool active = false;

  /// How strongly a component draws: in full on the rehearsal pass while
  /// [rehearsing] (the scene's rule), and as it [otherwise] would anywhere
  /// else, which under the loading screen is usually not at all.
  static double strength({
    required bool rehearsing,
    required double otherwise,
  }) => rehearsing && active ? 1.0 : otherwise;
}
