import 'package:portfolio/domain/config/logo_config.dart';

/// Spring-driven horizontal line that trails the cursor.
///
/// Each of the two lines flanking "TAP TO ENTER" is one of these. They are
/// pulled toward a target offset by a damped spring and stretch in proportion
/// to how fast they are travelling, which is what gives the affordance its
/// elastic feel rather than a rigid slide.
///
/// Pure Dart, no Flame types — the physics is the interesting part and this
/// keeps it testable without a game loop.
class BouncyLine {
  /// Where the line currently sits, relative to its rest position.
  double position = 0;

  /// Where it is being pulled toward.
  double target = 0;

  double velocity = 0;

  /// Length multiplier. Grows with speed, settles back to 1 at rest.
  double scale = 1;

  /// Advances the simulation by [dt] seconds.
  ///
  /// The step is clamped to [LogoConfig.maxStep]: explicit Euler integration
  /// diverges once `dt` is large relative to the spring's period, and a
  /// backgrounded tab hands back exactly that kind of frame. Without the
  /// clamp the line would fling off screen on the first frame after a stall.
  void update(double dt) {
    final step = dt.clamp(0.0, LogoConfig.maxStep);

    final springForce = (target - position) * LogoConfig.springStiffness;
    final dampingForce = -velocity * LogoConfig.springDamping;
    final acceleration =
        (springForce + dampingForce) / LogoConfig.springMass;

    velocity += acceleration * step;
    position += velocity * step;

    final targetScale =
        1 +
        (velocity.abs() / LogoConfig.lineVelocityScaleFactor).clamp(
          0.0,
          LogoConfig.lineMaxScale - 1,
        );
    scale += (targetScale - scale) * LogoConfig.lineScaleSpeed * step;
  }

  /// Drops the line back to rest without animating.
  void reset() {
    position = 0;
    target = 0;
    velocity = 0;
    scale = 1;
  }
}
