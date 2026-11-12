import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/gallery_camera_path.dart';
import 'package:portfolio/domain/gallery/gallery_dimensions.dart';
import 'package:portfolio/domain/gallery/keyboard_layout.dart';

/// The whole skills board fits the screen at the board, phone included.
void main() {
  double visibleWidth(double aspect) {
    final r = GalleryCameraPath.orbitRadiusFor(aspect);
    return 2 * r * math.tan(GalleryDimensions.fovRadians / 2) * aspect;
  }

  final board = KeyboardLayout.boardWidth * KeyboardLayout.scale;

  test('a laptop keeps the rest pose', () {
    expect(
      GalleryCameraPath.orbitRadiusFor(16 / 9),
      GalleryCameraPath.hallOrbitRadius,
    );
  });

  for (final phone in <double>[390 / 844, 360 / 800]) {
    test('a phone (${phone.toStringAsFixed(3)}) sees the whole board', () {
      // The bug: every row's end keys were cut off a phone held upright.
      expect(visibleWidth(phone), greaterThanOrEqualTo(board));
    });
  }

  test('it never stands closer than the rest pose', () {
    for (final aspect in <double>[0.4, 0.5, 1, 16 / 9, 21 / 9]) {
      expect(
        GalleryCameraPath.orbitRadiusFor(aspect),
        greaterThanOrEqualTo(GalleryCameraPath.hallOrbitRadius),
      );
    }
  });
}
