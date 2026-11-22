import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/config/title_shine.dart';

void main() {
  group("the title's shine (PORTFOLIO-30)", () {
    test('2x ships', () {
      expect(TitleShine.radiusScale, 2);
      expect(TitleShine.inUse, TitleShine.radiusScale);
    });

    test('desktop looks as shipped: 1600 px for the 518 px name at 2x', () {
      expect(
        TitleShine.radiusFor(nameWidth: 518, devicePixelRatio: 1, scale: 2),
        closeTo(1600, 1e-6),
      );
    });

    test('a phone gets the same share of its own name', () {
      double share(double name, double dpr) =>
          TitleShine.radiusFor(nameWidth: name, devicePixelRatio: dpr) /
          (name * dpr);
      expect(share(341, 2.625), closeTo(share(518, 1), 1e-9));
      expect(share(300, 3), closeTo(share(518, 1), 1e-9));
    });

    test('the shader takes the radius; the ambient keeps its own', () {
      final frag = File('assets/shaders/metallic_text.frag').readAsStringSync();
      expect(frag, contains('uniform float uShineRadius;'));
      expect(frag, contains('smoothstep(uShineRadius, 0.0, dist)'));
      expect(
        frag,
        contains('float glow = smoothstep(lightRadius, 0.0, dist);'),
      );
      final component = File(
        'lib/presentation/game/metallic_text_component.dart',
      ).readAsStringSync();
      expect(component, contains('TitleShine.radiusFor('));
    });
  });
}
