import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:portfolio/domain/config/pointer_config.dart';

/// Where the scene's pointer is coming from (PORTFOLIO-27), and the value
/// `pointer_source` carries in the analytics.
enum PointerSource {
  /// A mouse that has moved recently (desktop).
  mouse,

  /// A finger on the screen, while it is down.
  touch,

  /// The phone's tilt, around how it was held when the scene appeared.
  tilt,

  /// The idle drift: no finger, no tilt, a mouse at rest.
  drift,

  /// Nothing to follow: the light at the centre. Reduced motion asks for
  /// it, and a desktop whose mouse has not moved yet waits here before its
  /// drift begins.
  still,
}

/// What became of the iPhone's motion permission, for `tilt_permission`.
enum TiltPermission {
  granted,
  denied,

  /// The browser wants to be asked, and has not been yet.
  notAsked,

  /// The browser gives tilt without asking (Android Chrome), or has none.
  notNeeded;

  /// The value the analytics carry.
  String get wire => switch (this) {
    granted => 'granted',
    denied => 'denied',
    notAsked => 'not_asked',
    notNeeded => 'not_needed',
  };
}

/// The phone's tilt as a pointer on the screen. Pure.
abstract final class TiltPointer {
  /// The pointer for a reading of [beta] (front to back) and [gamma] (side
  /// to side), in degrees, around the [baseBeta] / [baseGamma] the phone was
  /// held at when the scene appeared, on a [viewport] whose screen is turned
  /// [screenAngle] degrees (0, 90, 180, 270: `screen.orientation.angle`).
  ///
  /// [PointerConfig.tiltRange] either way reaches [travel] of the way to
  /// the edge, and no further: like a marble, tipping the right edge down
  /// rolls it right, tipping the top away rolls it up.
  static Vector2 at({
    required double beta,
    required double gamma,
    required double baseBeta,
    required double baseGamma,
    required Vector2 viewport,
    double screenAngle = 0,
    double travel = 1,
  }) {
    // In the device's own frame, x to its right, y to its top.
    final dx = _wrap(gamma - baseGamma) / PointerConfig.tiltRange;
    final dy = _wrap(beta - baseBeta) / PointerConfig.tiltRange;
    // Into the screen's frame: the device turned by the screen's angle.
    final a = screenAngle * math.pi / 180;
    final sx = (dx * math.cos(a) - dy * math.sin(a)).clamp(-1.0, 1.0);
    final sy = (dx * math.sin(a) + dy * math.cos(a)).clamp(-1.0, 1.0);
    final half = viewport / 2;
    // Screen y grows downward; tipping the top away (beta up) rolls it up.
    return Vector2(
      half.x + sx * half.x * travel,
      half.y - sy * half.y * travel,
    );
  }

  /// An angle difference folded into -180..180.
  static double _wrap(double d) {
    var v = d % 360;
    if (v > 180) v -= 360;
    if (v < -180) v += 360;
    return v;
  }
}

/// The idle drift: a slow, calm path round the centre. Pure.
abstract final class DriftPath {
  /// Where the drift is [seconds] after it began, on a [viewport], reaching
  /// [travel] of the way to the edge at most. A figure of eight (two sines
  /// at 1:2): smooth, never still, never at an edge, and closed: one full
  /// pass takes [PointerConfig.driftPeriod]. It starts at the centre.
  static Vector2 at(double seconds, Vector2 viewport, {double travel = 1}) {
    final w = 2 * math.pi * seconds / PointerConfig.driftPeriod;
    final reach = PointerConfig.driftReach * travel;
    final half = viewport / 2;
    return Vector2(
      half.x + math.sin(w) * half.x * reach,
      half.y + math.sin(2 * w) * half.y * reach * 0.5,
    );
  }
}
