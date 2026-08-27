/// Render order for the scene's layers.
///
/// Ordering here is not cosmetic. Two of these layers are full-screen shader
/// passes that write **opaque** colour — the god-ray floor and the animated
/// backdrop — so they cannot be composited over one another. Whichever sits
/// higher completely hides the other, and the backdrop's fade is a crossfade
/// from one full-screen look to the next rather than a reveal of something
/// beneath it.
///
/// Getting [shadow] and [backdrop] the wrong way round produces a backdrop
/// that is running, updating and completely invisible, with nothing in the
/// logs to say so.
abstract final class SceneLayers {
  /// The lit floor: the god-ray pass that gives the mark its relief. Opaque
  /// and full-screen.
  static const int shadow = -20;

  /// The animated backdrop for the title stage. Opaque and full-screen, and
  /// deliberately **above** [shadow] — it replaces the lit floor as the title
  /// takes over.
  static const int backdrop = -10;

  /// The mark itself.
  static const int mark = 0;

  /// "TAP TO ENTER" and its lines.
  static const int affordance = 5;

  /// The hero title stage.
  static const int title = 10;

  /// The bold-text stage. Above the title, which it replaces, and below the
  /// cue, which stays reachable throughout.
  static const int boldText = 15;

  /// The scroll cue, above everything — it is the one thing the user is meant
  /// to be able to hit.
  static const int scrollCue = 20;
}
