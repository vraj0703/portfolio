import 'dart:math' as math;
import 'dart:ui' show Color;

/// WCAG 2 contrast between two opaque colours: 1 (none) to 21 (black on
/// white). Non-text marks such as icons want at least 3.
abstract final class Contrast {
  static const double forIcons = 3;

  static double ratio(Color a, Color b) {
    final la = _luminance(a);
    final lb = _luminance(b);
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  static double _luminance(Color c) =>
      0.2126 * _linear(c.r) + 0.7152 * _linear(c.g) + 0.0722 * _linear(c.b);

  static double _linear(double v) =>
      v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
}
