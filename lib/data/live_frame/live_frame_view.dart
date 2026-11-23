/// A live web page in an iframe, laid over a gallery frame (PORTFOLIO-6).
///
/// Conditionally imported the same way `PageVisibility` is: an iframe is a
/// browser's, and everywhere else there is none (the picture stays).
library;

export 'live_frame_view_stub.dart'
    if (dart.library.js_interop) 'live_frame_view_web.dart';
