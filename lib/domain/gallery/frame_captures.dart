/// The projects whose corridor frame shows a picture of their live site
/// (PORTFOLIO-6), and where it is.
///
/// The picture is made by one command, `python tool/capture_frame.py <id>`,
/// which writes `assets/frames/<id>.webp` at the card's exact shape (3.56 x
/// 2.56) and `assets/frames/<id>.json` with the URL and the capture date.
/// Refreshing a picture is running it again; nothing here changes.
abstract final class FrameCaptures {
  /// Project ids with a capture.
  static const Set<String> projects = <String>{'shunya-systems'};

  /// The picture's asset for project [id], or null when it has none.
  static String? assetFor(String id) =>
      projects.contains(id) ? 'assets/frames/$id.webp' : null;

  /// The capture's record (URL, date, viewport) beside the picture.
  static String recordFor(String id) => 'assets/frames/$id.json';
}
