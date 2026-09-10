/// Always visible, for everywhere that is not a browser.
///
/// A test on the Dart VM and a desktop build both draw continuously whatever
/// else is on screen, so there is no hidden state to report — and answering
/// `true` keeps every caller on the path that waits for real frames, which is
/// the correct one when frames are actually being produced.
abstract final class PageVisibility {
  static bool get isVisible => true;
}
