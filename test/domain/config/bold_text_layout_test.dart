import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/config/bold_text_layout.dart';

/// "Crafting clarity from chaos." set for the screen it is on.
void main() {
  const phone = Size(412, 915);
  const small = Size(360, 640);
  const laptop = Size(1440, 900);

  test('a laptop keeps the desktop numbers exactly', () {
    expect(BoldTextLayout.wrapWidthFor(laptop), BoldTextLayout.maxWrapWidth);
    expect(BoldTextLayout.scaleFor(laptop), 1.0);
  });

  test('a phone wraps inside its own width, less 16 dp each side', () {
    expect(BoldTextLayout.wrapWidthFor(phone), 412 - 32);
    expect(BoldTextLayout.wrapWidthFor(small), 360 - 32);
  });

  test('a phone scales the type to about Material display-small', () {
    expect(64 * BoldTextLayout.scaleFor(phone), closeTo(36.6, 0.1));
    expect(
      BoldTextLayout.scaleFor(const Size(200, 400)),
      BoldTextLayout.minScale,
    );
  });

  test('never a negative wrap on a sliver of a window', () {
    expect(BoldTextLayout.wrapWidthFor(const Size(20, 400)), 0);
  });
}
