/// How far into one piece the visitor has gone.
///
/// Three levels, and Escape (or the sheet's own back) climbs out one at a
/// time: the sheet closes back to the piece, and only then does the piece
/// let go of the camera. Closing straight to the corridor from the sheet
/// would throw away the place the visitor was reading from.
enum GalleryDepth {
  /// Walking the corridor: drawings and names.
  corridor,

  /// Standing at one piece, its label readable.
  focused,

  /// The case open on the sheet, over the piece.
  reading;

  /// One level out, or null when there is nowhere further out to go.
  GalleryDepth? get back => switch (this) {
    GalleryDepth.reading => GalleryDepth.focused,
    GalleryDepth.focused => GalleryDepth.corridor,
    GalleryDepth.corridor => null,
  };

  /// Where the visitor is, from what the view holds.
  static GalleryDepth of({required bool focused, required bool reading}) {
    if (!focused) return GalleryDepth.corridor;
    return reading ? GalleryDepth.reading : GalleryDepth.focused;
  }
}
