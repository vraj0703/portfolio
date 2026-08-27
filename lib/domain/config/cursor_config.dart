/// How the scene follows the pointer.
///
/// The cursor never drives anything directly. Everything it touches — the
/// light, the titles — reads a *smoothed* position instead, so the scene
/// glides after the pointer rather than snapping to it. Snapping is what
/// makes a lit scene feel like a cursor-tracking gimmick instead of a room
/// with a light in it.
abstract final class CursorConfig {
  /// The light sits slightly below the pointer, so the mark is lit from
  /// above rather than dead-on.
  static const double glowOffset = 10;

  /// Smoothing rates, in units of "fraction closed per second". Two of them:
  /// a long throw should catch up briskly, but the same rate applied to small
  /// movements makes the light twitchy.
  static const double smoothSpeedFar = 30;
  static const double smoothSpeedNear = 24;

  /// Distance beyond which the light is considered to be chasing rather than
  /// tracking.
  static const double farThreshold = 100;

  /// How far the titles shift relative to the pointer's distance from centre.
  ///
  /// The two differ on purpose: moving the line beneath the name at a
  /// slightly slower rate reads as depth rather than as one flat plate
  /// sliding around.
  static const double titleParallax = 0.02;
  static const double secondaryTitleParallax = 0.015;

  /// Ceiling on the step so a stalled frame cannot teleport the light.
  static const double maxStep = 1 / 30;
}
