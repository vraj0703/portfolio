import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/config/loading_layout.dart';
import 'package:portfolio/domain/config/logo_config.dart';

/// The loading screen sized from the device's screen.
void main() {
  const phone = Size(412, 915);
  const small = Size(360, 640);
  const laptop = Size(1280, 800);

  test('a portrait phone sizes the mark from its short side', () {
    final old = LogoConfig.loadingMarkWidthFor(
      viewportWidth: phone.width,
      viewportHeight: phone.height,
    );
    final now = LoadingLayout.markWidthFor(phone);
    expect(now, closeTo(phone.width * LoadingLayout.portraitMarkShare, 1e-9));
    expect(now, greaterThan(old * 1.5), reason: 'it was about 96 px');
  });

  test('the mark never takes more than half the height', () {
    for (final s in <Size>[phone, small, const Size(500, 520)]) {
      final h = LoadingLayout.markWidthFor(s) * LogoConfig.markAspect;
      expect(h, lessThanOrEqualTo(s.height * LogoConfig.markMaxHeightFactor + 1e-9));
    }
  });

  test('a landscape screen keeps the scene rule exactly', () {
    expect(
      LoadingLayout.markWidthFor(laptop),
      LogoConfig.loadingMarkWidthFor(
        viewportWidth: laptop.width,
        viewportHeight: laptop.height,
      ),
    );
  });

  test('the readout has the screen, less its margins, not the mark', () {
    final mark = LoadingLayout.markWidthFor(phone);
    expect(LoadingLayout.readoutWidthFor(phone, mark), phone.width - 32);
    expect(LoadingLayout.readoutWidthFor(phone, mark), greaterThan(mark));
    expect(LoadingLayout.readoutAlignsRight(phone), isFalse);
  });

  test('a landscape screen keeps the readout under the mark, right-aligned', () {
    final mark = LoadingLayout.markWidthFor(laptop);
    expect(LoadingLayout.readoutWidthFor(laptop, mark), mark);
    expect(LoadingLayout.readoutAlignsRight(laptop), isTrue);
  });

  test('its type scales down on a small screen, never up', () {
    expect(LoadingLayout.readoutScaleFor(laptop), 1.0);
    expect(LoadingLayout.readoutScaleFor(phone), closeTo(412 / 480, 1e-9));
    expect(LoadingLayout.readoutScaleFor(const Size(200, 300)),
        LoadingLayout.minReadoutScale);
  });
}
