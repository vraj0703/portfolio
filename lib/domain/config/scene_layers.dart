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

  /// The dark the contact screen comes up out of.
  ///
  /// Above the ground and *below* the mark, which is the whole reason it is
  /// a layer here rather than a sheet over the finished frame. The mark
  /// flies in from the corridor and is the one thing carried across the
  /// handover between the two renderers; a veil painted over it would blink
  /// it out at exactly the moment it arrives.
  static const int contactArrival = -5;

  /// The mark itself.
  static const int mark = 0;

  /// The contact screen's dim.
  ///
  /// Above the ground and the mark, below the affordance. That is the whole
  /// point of it being a layer rather than a sheet over the finished frame:
  /// the room stands back and the thing being offered does not.
  static const int contactDim = 3;

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
