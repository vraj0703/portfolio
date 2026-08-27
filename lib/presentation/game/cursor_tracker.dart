import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:portfolio/domain/config/cursor_config.dart';

/// Smoothed pointer position for everything in the scene that follows the
/// cursor.
///
/// The pointer jumps; the scene should not. This eases a virtual position
/// toward the real one at a rate that depends on how far behind it is, so a
/// long throw catches up briskly while small movements stay calm.
///
/// Pure Dart, no Flame game required — the easing is the interesting part and
/// this keeps it testable without a game loop.
class CursorTracker {
  /// Where the pointer actually is, in screen space.
  Vector2 target = Vector2.zero();

  /// Where the scene believes it is. This is what components should read.
  Vector2 position = Vector2.zero();

  /// Unit vector from the centre of the viewport toward the pointer, also
  /// smoothed. The shadow pass uses it to lean the rays.
  Vector2 direction = Vector2(0, -1);

  Vector2 _targetDirection = Vector2(0, -1);

  bool _seenPointer = false;

  /// True once the pointer has actually moved. Before that the scene lights
  /// itself from the centre rather than from the top-left corner, which is
  /// where an untouched pointer would otherwise put it.
  bool get hasPointer => _seenPointer;

  /// Places the virtual position without animating. Used on first layout so
  /// the light does not visibly fly in from nowhere.
  void reset(Vector2 centre) {
    target = centre.clone();
    position = centre.clone();
    direction = Vector2(0, -1);
    _targetDirection = Vector2(0, -1);
  }

  /// Records where the pointer is now.
  void moveTo(Vector2 pointer, Vector2 viewport) {
    _seenPointer = true;
    target = pointer + Vector2(0, CursorConfig.glowOffset);

    final fromCentre = pointer - viewport / 2;
    if (fromCentre.length2 > 0) {
      _targetDirection = fromCentre.normalized();
    }
  }

  /// Eases the virtual position toward the pointer.
  void update(double dt) {
    final step = dt.clamp(0.0, CursorConfig.maxStep);

    final distance = (target - position).length;
    final speed = distance > CursorConfig.farThreshold
        ? CursorConfig.smoothSpeedFar
        : CursorConfig.smoothSpeedNear;

    // Curving the interpolant, rather than using it raw, keeps the approach
    // from decelerating into a long tail as the gap closes.
    final t = Curves.easeOutQuad.transform((speed * step).clamp(0.0, 1.0));

    position.lerp(target, t);
    direction.lerp(_targetDirection, t);
  }

  /// Offset for a parallax layer, given how far the pointer sits from the
  /// centre of [viewport].
  Vector2 parallax(Vector2 viewport, double factor) =>
      (position - viewport / 2) * factor;
}
