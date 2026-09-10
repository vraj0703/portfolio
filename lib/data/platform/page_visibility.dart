/// Whether the page the app is drawn into is currently on screen.
///
/// Exists for one reason: a browser stops `requestAnimationFrame` entirely
/// for a hidden tab, and Flutter web drives its frame loop from it. So in a
/// background tab the engine produces *no frames at all* — and anything that
/// waits on one waits indefinitely.
///
/// That is not a slow path, it is a stall that only the tab regaining focus
/// releases. The gallery build reports progress between every step and
/// awaited `SchedulerBinding.instance.endOfFrame` each time, so switching
/// tabs during loading froze the whole build until the visitor came back.
///
/// Conditionally imported the same way `RadioStream` is: the answer is a fact
/// about a browser, and everywhere that is not one has no such concept.
library;

export 'page_visibility_stub.dart'
    if (dart.library.js_interop) 'page_visibility_web.dart';
