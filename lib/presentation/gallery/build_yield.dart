import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:portfolio/data/platform/page_visibility.dart';

/// Lets the loading screen draw while the gallery builds behind it.
///
/// The gallery is built on the main thread — the web has no isolates — while
/// the loading screen is up and animating. A build that never gives a frame
/// back freezes that animation, and the bar with it, for as long as it runs.
/// Every place that does real work between awaits calls [frame]: one texture
/// decoded, one texture uploaded, a slice of a pixel loop, one card baked,
/// one step of the build reported.
///
/// **Paced, not every step.** There are hundreds of these points, many of
/// them a millisecond of work. Waiting a whole frame at each would spend
/// more time waiting than building; the steps instead run back to back until
/// about one [budget] of work has piled up, and only then let a frame
/// through. The loading animation keeps its frames and the build keeps its
/// pace.
abstract final class BuildYield {
  /// How much work runs back to back before a frame is let through.
  ///
  /// Two frames at 60 Hz: the loading animation never drops below about
  /// thirty frames a second for anything Dart can split, and a run of cheap
  /// steps is not spending a frame each to say the same thing.
  static const Duration budget = Duration(milliseconds: 32);

  /// Time since a frame was last let through.
  ///
  /// Static because the build is: `GalleryScene.warmUp` memoises one build
  /// for the life of the app, so there is never a second one beside it.
  static final Stopwatch _sinceFrame = Stopwatch();

  /// Lets a frame through if about [budget] of work has run since the last.
  static Future<void> frame() async {
    // A hidden tab draws no frames, so waiting for one would stall the build
    // until the visitor came back. Nothing is watching; run flat out.
    if (!PageVisibility.isVisible) return;

    if (!_sinceFrame.isRunning) _sinceFrame.start();
    if (_sinceFrame.elapsed < budget) return;

    await SchedulerBinding.instance.endOfFrame;
    _sinceFrame.reset();
  }
}
