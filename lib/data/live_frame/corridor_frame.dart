/// The live site laid on a corridor frame in perspective (the live-in-the-
/// corridor prototype, PORTFOLIO-6). Web only; elsewhere nothing.
library;

export 'corridor_frame_stub.dart'
    if (dart.library.js_interop) 'corridor_frame_web.dart';
