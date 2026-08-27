import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/config/scene_layers.dart';

void main() {
  group('SceneLayers', () {
    test('the backdrop sits above the lit floor', () {
      // Load-bearing, and easy to get backwards. Both are opaque full-screen
      // shader passes, so the lower one is not dimmed by the upper — it is
      // entirely invisible. Inverting these gives a backdrop that runs,
      // updates, and never appears.
      expect(SceneLayers.backdrop, greaterThan(SceneLayers.shadow));
    });

    test('both full-screen passes sit behind the scene content', () {
      expect(SceneLayers.backdrop, lessThan(SceneLayers.mark));
      expect(SceneLayers.shadow, lessThan(SceneLayers.mark));
    });

    test('the affordance and title draw over the mark', () {
      expect(SceneLayers.affordance, greaterThan(SceneLayers.mark));
      expect(SceneLayers.title, greaterThan(SceneLayers.mark));
    });

    test('every layer is distinct', () {
      const layers = <int>[
        SceneLayers.shadow,
        SceneLayers.backdrop,
        SceneLayers.mark,
        SceneLayers.affordance,
        SceneLayers.title,
      ];
      expect(layers.toSet(), hasLength(layers.length));
    });
  });
}
