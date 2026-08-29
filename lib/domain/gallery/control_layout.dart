import 'package:vector_math/vector_math.dart';

import 'gallery_layout.dart';

/// What one of the three controls does.
enum ControlAction { previous, exit, next }

/// One control, placed on the wall beneath the work.
class ControlPlacement {
  const ControlPlacement({
    required this.action,
    required this.position,
    required this.extents,
  });

  final ControlAction action;
  final Vector3 position;

  /// The area that answers a tap, in the same convention the frames use:
  /// `x` spans the wall, `y` is height. See `FramePicker.cornersOf`.
  final Vector3 extents;
}

/// Where the three controls sit when a piece is focused.
///
/// Pure placement, so the arrangement can be checked without a renderer. The
/// mistake worth catching is not a control that fails to draw — that is
/// obvious — but one that draws on the wrong side, which looks deliberate and
/// sends the visitor the opposite way from the one they asked for.
abstract final class ControlLayout {
  /// How far beneath the frame's bottom edge the row sits.
  ///
  /// Raised off the floor. At the original drop the icons' lower edge met the
  /// ground exactly, and a small metal object resting on a floor in a room
  /// this dim has nothing behind it to separate it from the floor — it reads
  /// as part of the tiling rather than as something to press. Lifted clear,
  /// it has shadow under it and a silhouette against the wall.
  static const double dropBelowFrame = 0.34;

  /// Gap between one control and the next, centre to centre.
  static const double spacing = 0.8;

  /// How far the controls stand off the wall — clear of the plaster, and of
  /// the frame's own moulding.
  static const double standoff = 0.12;

  /// Height of an icon in world units, and the size of its tap target.
  static const double iconSize = 0.36;

  /// The row for [frame], omitting whichever ends are closed.
  ///
  /// The slot at *larger* z always holds [ControlAction.previous], on both
  /// walls. That is the slot nearer the entrance, so the control that takes
  /// the visitor back is always on the side the way back is on — and because
  /// the camera reads the two walls from opposite sides, that single rule is
  /// what puts the arrow on the correct side of the screen for each of them
  /// without a special case.
  static List<ControlPlacement> below(
    Placement frame, {
    required bool canGoBack,
    required bool canGoForward,
  }) {
    // Frames hang just inside the wall they belong to, so the sign of their x
    // is the wall; stepping the other way is stepping into the corridor.
    final inward = frame.position.x.isNegative ? 1.0 : -1.0;
    final x = frame.position.x + inward * standoff;
    final y = frame.position.y - frame.extents.y / 2 - dropBelowFrame;

    Vector3 at(double dz) => Vector3(x, y, frame.position.z + dz);
    final extents = Vector3(iconSize, iconSize, 0.06);

    return <ControlPlacement>[
      if (canGoBack)
        ControlPlacement(
          action: ControlAction.previous,
          position: at(spacing),
          extents: extents,
        ),
      ControlPlacement(
        action: ControlAction.exit,
        position: at(0),
        extents: extents,
      ),
      if (canGoForward)
        ControlPlacement(
          action: ControlAction.next,
          position: at(-spacing),
          extents: extents,
        ),
    ];
  }

  /// Which way an arrow icon must point, in *design* radians about the
  /// vertical, for each direction of travel.
  ///
  /// The arrow model's tip runs along its own `+X`, so these turn that onto
  /// the corridor's axis. Independent of which wall the piece hangs on:
  /// pointing along z does not care which side you are standing on.
  static const double towardEntrance = 1.5707963267948966;
  static const double towardBackWall = -1.5707963267948966;

  static double aimFor(ControlAction action) => switch (action) {
    ControlAction.previous => towardEntrance,
    ControlAction.next => towardBackWall,
    ControlAction.exit => 0,
  };
}
