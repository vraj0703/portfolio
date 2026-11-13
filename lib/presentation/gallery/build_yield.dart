import 'package:flutter/scheduler.dart' show SchedulerBinding;

/// Lets a frame through during a background build of the gallery.
///
/// The gallery is built while the title is on screen (PORTFOLIO-8), on the
/// main thread — the web has no isolates — so any step that runs longer than
/// a frame takes that frame from the title. Every place that does real work
/// between awaits calls [frame]: one texture decoded, one texture uploaded,
/// a slice of a pixel loop, one card or legend baked. In the background it
/// waits for the next frame to be drawn; once a visitor is waiting on the
/// build it returns at once and the build runs flat out.
abstract final class BuildYield {
  /// Whether the build in flight is one nobody is waiting for yet.
  static bool background = false;

  /// Yields a frame if the build is in the background.
  static Future<void> frame() async {
    if (!background) return;
    await SchedulerBinding.instance.endOfFrame;
  }
}
