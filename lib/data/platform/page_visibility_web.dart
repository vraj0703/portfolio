import 'package:web/web.dart' as web;

/// The browser's own answer, read fresh each time.
///
/// Not cached and not listened to: the callers ask at the moment they are
/// about to wait for a frame, and a value stored at any earlier moment is a
/// value that can be wrong by then.
abstract final class PageVisibility {
  static bool get isVisible => web.document.visibilityState != 'hidden';
}
