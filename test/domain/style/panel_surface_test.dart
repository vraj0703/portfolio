import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/style/colors.dart';

double _lum(Color c) {
  double lin(double v) =>
      v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4) as double;
  return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
}

double _contrast(Color a, Color b) {
  final la = _lum(a), lb = _lum(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  const colors = DefaultAppColors();

  group('one panel for the dialog, the drawer and the contact links', () {
    test('every surface reads the same definition', () {
      expect(colors.creditsPanel, colors.panelSurface);
      expect(colors.menuPanel, colors.panelSurface);
      expect(colors.contactPlate, colors.panelSurface);
      expect(colors.creditsBorder, colors.panelBorder);
      expect(colors.contactPressed, colors.panelPressed);
    });

    test('its ink reads at 4.5:1 or better, resting and active', () {
      expect(
        _contrast(colors.panelInk, colors.panelSurface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(colors.panelInkActive, colors.panelSurface),
        greaterThan(_contrast(colors.panelInk, colors.panelSurface)),
      );
    });
  });
}
