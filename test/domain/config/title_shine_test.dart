import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/config/title_shine.dart';

void main() {
  group('the title\'s shine (PORTFOLIO-30)', () {
    test('wider than it was by default, within reason', () {
      expect(TitleShine.radiusScale, 2);
      expect(TitleShine.inUse, TitleShine.radiusScale);
    });

    test('the shader widens the shine only, not the ambient light', () {
      final frag = File('assets/shaders/metallic_text.frag').readAsStringSync();
      expect(frag, contains('uniform float uShineScale;'));
      expect(
        frag,
        contains('smoothstep(lightRadius * uShineScale, 0.0, dist)'),
      );
      // The ambient keeps the light's own falloff.
      expect(
        frag,
        contains('float glow = smoothstep(lightRadius, 0.0, dist);'),
      );
      final component = File(
        'lib/presentation/game/metallic_text_component.dart',
      ).readAsStringSync();
      expect(component, contains('..setFloat(11, TitleShine.inUse)'));
    });
  });
}
