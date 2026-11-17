import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/models/loading_phase.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/game/backdrop_component.dart';
import 'package:portfolio/presentation/screen/my_game.dart';

void main() {
  group('the title stage is rehearsed under the curtain', () {
    test('while loading, and on no other stage', () {
      // Every other stage is on screen: a rehearsal there would be seen.
      expect(const SceneState.loading().rehearsesTitle, isTrue);
      for (final state in <SceneState>[
        const SceneState.logo(),
        const SceneState.logoOverlayRemoving(),
        const SceneState.titleLoading(),
        const SceneState.title(),
        const SceneState.active(),
        const SceneState.gallery(),
        const SceneState.contact(),
      ]) {
        expect(state.rehearsesTitle, isFalse, reason: '$state');
      }
    });

    test('and the bar waits for it, in a phase of its own', () {
      expect(LoadingPhase.values, contains(LoadingPhase.rehearsal));
      expect(MyGame.rehearsalProgress(0), 0);
      expect(MyGame.rehearsalProgress(MyGame.rehearsalFrames), 1);
      expect(MyGame.rehearsalProgress(MyGame.rehearsalFrames + 3), 1);
      expect(MyGame.rehearsalFrames, greaterThanOrEqualTo(2));
    });
  });

  group('the backdrop rehearses its real draw', () {
    test('both paths, opaque and faded: they are two GPU programs', () {
      final passes = BackdropComponent.passesFor(rehearsing: true, opacity: 0);
      expect(passes, contains(1));
      expect(passes.where((o) => o > 0.001 && o < 0.999), isNotEmpty);
    });

    test('and otherwise draws as before', () {
      expect(
        BackdropComponent.passesFor(rehearsing: false, opacity: 0),
        isEmpty,
      );
      expect(BackdropComponent.passesFor(rehearsing: false, opacity: 0.4), [
        0.4,
      ]);
      expect(BackdropComponent.passesFor(rehearsing: false, opacity: 1), [1]);
    });
  });
}
