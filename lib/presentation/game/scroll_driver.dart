import 'dart:math' as math;

import 'package:portfolio/domain/config/bold_text_config.dart';

/// Owns the scroll position for the bold-text stage.
///
/// Deliberately *not* in the bloc. The offset changes every frame while the
/// user scrolls, and a bloc emitting sixty states a second to carry a double
/// is the wrong instrument — the bloc tracks which stage the scene is in, and
/// this tracks where the user is within it.
///
/// Two positions rather than one: [target] is where the input has asked to
/// be, [offset] is where the scene has actually reached. The gap between them
/// is the weight — scrolling moves the target instantly and the scene catches
/// up, which is what stops a trackpad flick from teleporting the sequence.
///
/// Pure Dart, so the physics can be tested without a game loop.
class ScrollDriver {
  ScrollDriver({
    this.extent = BoldTextConfig.extent,
    this.snapPoints = BoldTextConfig.snapPoints,
    this.progressExtent = BoldTextConfig.progressExtent,
  });

  final double extent;
  final double progressExtent;
  final List<double> snapPoints;

  double _target = 0;
  double _offset = 0;
  double _velocity = 0;
  double _springVelocity = 0;

  double? _snappingTo;

  /// Where the input has asked to be.
  double get target => _target;

  /// Where the scene has actually reached.
  double get offset => _offset;

  /// The scene's position as the shader's `0..1`.
  ///
  /// Clamped, because [extent] runs past [progressExtent] — the tail is dead
  /// travel and the sequence should stay finished through it, not wrap.
  double get progress => (_offset / progressExtent).clamp(0.0, 1.0);

  /// True once the sequence has played out and the scroll is spent.
  bool get isComplete => _target >= extent - 0.5;

  /// True while a pause is claiming the scroll.
  bool get isSnapping => _snappingTo != null;

  /// Speed of the target, in units per second.
  double get velocity => _velocity;

  /// Moves the target by [delta], interrupting any pause it is settling into.
  void scrollBy(double delta) {
    if (delta == 0) return;

    // A deliberate scroll always wins over a snap in progress; continuing to
    // pull toward a pause the user is actively scrolling away from feels like
    // the page fighting back.
    _snappingTo = null;
    _springVelocity = 0;

    _target = (_target + delta).clamp(0.0, extent);
  }

  /// Sends the scroll to the next pause, or to the end if none remain.
  ///
  /// This is what the arrow does. It steps the sequence rather than jumping
  /// it: the same positions the scroll would settle on, reached the same way,
  /// so clicking and scrolling cannot diverge.
  void advanceToNextPause() {
    final next = snapPoints
        .where((point) => point > _target + 1)
        .fold<double?>(null, (best, point) => best == null ? point : math.min(best, point));

    _snappingTo = next ?? extent;
    _springVelocity = 0;
  }

  /// Places the scroll without animating. Used on entry.
  void reset() {
    _target = 0;
    _offset = 0;
    _velocity = 0;
    _springVelocity = 0;
    _snappingTo = null;
  }

  void update(double dt) {
    final step = dt.clamp(0.0, BoldTextConfig.maxStep);
    if (step <= 0) return;

    final previousTarget = _target;

    _settleOntoPause(step);

    _velocity = (_target - previousTarget) / step;

    // Frame-rate independent chase, rather than `+= diff * dt * k`, which
    // moves a different fraction of the way at 60fps than at 120.
    final t = 1 - math.exp(-BoldTextConfig.inertia * step);
    _offset += (_target - _offset) * t;
  }

  void _settleOntoPause(double step) {
    // A pause may claim the scroll once it has slowed enough to be sitting
    // still rather than passing through.
    if (_snappingTo == null && _velocity.abs() <= BoldTextConfig.snapVelocityThreshold) {
      for (final point in snapPoints) {
        if ((_target - point).abs() <= BoldTextConfig.snapRadius) {
          if ((_target - point).abs() < 1) break; // already there
          _snappingTo = point;
          _springVelocity = 0;
          break;
        }
      }
    }

    final destination = _snappingTo;
    if (destination == null) return;

    final displacement = _target - destination;
    final acceleration = -BoldTextConfig.snapStiffness * displacement -
        BoldTextConfig.snapDamping * _springVelocity;

    _springVelocity += acceleration * step;
    _target = (_target + _springVelocity * step).clamp(0.0, extent);

    if (displacement.abs() < 1 && _springVelocity.abs() < 5) {
      _target = destination;
      _springVelocity = 0;
      _snappingTo = null;
    }
  }
}
