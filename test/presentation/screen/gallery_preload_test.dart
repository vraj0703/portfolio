import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/screen/flame_scene.dart';

/// PORTFOLIO-8: the gallery's background build starts only once the title
/// sequence has arrived, never while the title is still coming in.
void main() {
  test('nothing before the title has arrived starts it', () {
    for (final state in <SceneState>[
      const SceneState.loading(),
      const SceneState.logo(),
      const SceneState.title(),
    ]) {
      expect(GalleryPreload.shouldStart(state), isFalse, reason: '$state');
    }
  });

  test('the title settled, or any later stage, starts it', () {
    for (final state in <SceneState>[
      const SceneState.active(),
      const SceneState.gallery(),
      const SceneState.contact(),
    ]) {
      expect(GalleryPreload.shouldStart(state), isTrue, reason: '$state');
    }
  });
}
