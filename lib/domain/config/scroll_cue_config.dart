/// The downward arrow that invites the user onward from the title.
///
/// It is the only thing on screen telling the user the page continues, so it
/// has to move — a static arrow at the bottom of a full-bleed scene reads as
/// decoration. The bounce is slow and shallow: enough to catch the eye,
/// little enough not to nag.
abstract final class ScrollCueConfig {
  /// Distance from the bottom of the viewport to the arrow's rest position.
  static const double bottomMargin = 64;

  /// Width of the chevron; its height follows from the artwork's proportions.
  static const double size = 34;

  /// The original is a 24x24 chevron, and the path below is expressed in that
  /// space before being scaled to [size].
  static const double artboard = 24;

  /// How far it travels, and how long a full down-and-back takes.
  static const double bounceDistance = 15;
  static const Duration bouncePeriod = Duration(milliseconds: 3000);

  /// Fades in once the title has settled, rather than appearing at once —
  /// arriving abruptly under a title that took six seconds to resolve reads
  /// as a different screen.
  static const Duration fadeIn = Duration(milliseconds: 700);

  /// Drop shadow, which is what keeps it legible over the animated backdrop.
  static const double shadowOffsetY = 3;
  static const double shadowBlur = 6;

  /// Half-extent of the tap target around the arrow's centre.
  ///
  /// Deliberately larger than the artwork: the arrow is thin, and a hit box
  /// that matches it exactly is unpleasant to click and unusable on touch.
  static const double touchPadX = 28;
  static const double touchPadY = 26;
}
