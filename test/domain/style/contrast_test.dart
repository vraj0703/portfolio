import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/domain/style/contrast.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';

void main() {
  const colors = DefaultAppColors();

  test('the ratio is WCAG\'s', () {
    expect(
      Contrast.ratio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
      closeTo(21, 1e-9),
    );
    expect(Contrast.ratio(const Color(0xFF777777), const Color(0xFF777777)), 1);
  });

  // The ceiling behind the icons, read off the ROG's screenshots: the
  // corridor's darkest and the hall's brightest.
  const ceilings = <Color>[
    Color(0xFFACA9A1),
    Color(0xFFB9B6AD),
    Color(0xFFF7F2E7),
  ];

  test('the gallery ink reads on the ceiling, at least 3:1', () {
    for (final ceiling in ceilings) {
      expect(
        Contrast.ratio(colors.galleryChromeInk, ceiling),
        greaterThanOrEqualTo(Contrast.forIcons),
        reason: '$ceiling',
      );
    }
  });

  test('which the title\'s tint does not', () {
    expect(
      Contrast.ratio(colors.menuMark, ceilings.last),
      lessThan(Contrast.forIcons),
    );
  });

  test('the scene decides: dark ink in the gallery only', () {
    expect(const SceneState.gallery().chromeOnLight, isTrue);
    expect(const SceneState.title().chromeOnLight, isFalse);
    expect(const SceneState.active().chromeOnLight, isFalse);
  });
}
