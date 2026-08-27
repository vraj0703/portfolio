import 'package:vector_math/vector_math.dart';

/// Converts the gallery's design coordinates into flutter_scene's.
///
/// The gallery was laid out in the coordinates of the scene it was ported
/// from, where a camera looking down −Z sees +X on its right. flutter_scene
/// mirrors that: the same point lands on the opposite side of the screen.
///
/// Rather than negating every constant — which would leave the layout no
/// longer comparable against the source it came from, and would need
/// remembering at every new placement — everything crosses this boundary
/// exactly once, on its way into the renderer.
///
/// The symptom when this is missing is not a crash or a warning: the room
/// simply builds itself inside out. The left wall's work appears on the right,
/// and the testimonials end up on the wrong side of a room the visitor is
/// walking through in the right direction.
abstract final class SceneAxes {
  /// A position, in engine space.
  static Vector3 position(Vector3 design) =>
      Vector3(-design.x, design.y, design.z);

  /// A rotation about the vertical axis, in engine space.
  ///
  /// Mirroring an axis reverses the handedness of every rotation around the
  /// axes it is perpendicular to. Flipping the position without flipping this
  /// leaves each frame facing into the wall it hangs on.
  static double rotationY(double design) => -design;
}
