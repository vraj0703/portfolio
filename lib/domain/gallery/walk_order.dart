import 'gallery_layout.dart';

/// The order the visitor steps through the work in.
///
/// Named for the walk rather than for focus because Flutter already has a
/// `FocusOrder`, and two types with one name in the same file is a prefix
/// nobody reading this later would thank us for.
///
/// Not the order the frames were declared in, and not the order of either
/// wall on its own. The corridor is a walk, so the sequence that makes sense
/// is the one the visitor physically meets: by depth, both walls interleaved.
/// Stepping "next" from a piece on the left wall should land on the piece
/// opposite it rather than skipping past it to the far end of the same wall.
///
/// Pure ordering, kept out of the view so the ends can be tested. The two
/// bugs worth catching are silent ones: an arrow that stays live at the end
/// of the sequence and does nothing when pressed, and an order that makes
/// "next" jump backwards down the corridor.
class WalkOrder {
  WalkOrder(List<Placement> pieces)
    : _frames = _sorted(pieces),
      assert(pieces.isNotEmpty, 'a gallery with no work has nothing to focus');

  final List<Placement> _frames;

  List<Placement> get frames => List<Placement>.unmodifiable(_frames);

  int get length => _frames.length;

  /// The pieces on the same wall as [frame], in the order they are met.
  ///
  /// Stepping runs along one wall rather than across both. Crossing the
  /// corridor swings the camera through a hundred and eighty degrees to look
  /// at the wall behind where the visitor was just standing, which loses them
  /// completely — the arrows should walk them down a wall, not spin them
  /// around in place.
  List<Placement> _wallOf(Placement frame) => _frames
      .where((f) => f.position.x.isNegative == frame.position.x.isNegative)
      .toList();

  static List<Placement> _sorted(List<Placement> pieces) {
    final frames = pieces
        .where((p) => p.kind == SurfaceKind.frame)
        .toList();

    // Descending z: the corridor runs toward negative z, so the piece
    // nearest the entrance has the *largest* z and is met first.
    frames.sort((a, b) {
      final byDepth = b.position.z.compareTo(a.position.z);
      if (byDepth != 0) return byDepth;

      // Two pieces facing each other across the corridor are at the same
      // depth. Left before right, so the pair is read in one consistent
      // direction rather than in whichever order they were declared.
      return a.position.x.compareTo(b.position.x);
    });

    return frames;
  }

  int indexOf(Placement frame) =>
      _frames.indexWhere((f) => f.project?.id == frame.project?.id);

  int _indexOnWall(Placement frame, List<Placement> wall) =>
      wall.indexWhere((f) => f.project?.id == frame.project?.id);

  bool hasPrevious(Placement frame) => previous(frame) != null;

  bool hasNext(Placement frame) => next(frame) != null;

  /// The piece before [frame], or null at the start.
  ///
  /// Null rather than wrapping. Wrapping would make the arrows never
  /// disable, and a visitor stepping forward through the work would silently
  /// arrive back where they began with no indication they had finished.
  Placement? previous(Placement frame) {
    final wall = _wallOf(frame);
    final i = _indexOnWall(frame, wall);
    return i > 0 ? wall[i - 1] : null;
  }

  /// The piece after [frame] on the same wall, or null at that wall's end.
  Placement? next(Placement frame) {
    final wall = _wallOf(frame);
    final i = _indexOnWall(frame, wall);
    return i >= 0 && i < wall.length - 1 ? wall[i + 1] : null;
  }

}
