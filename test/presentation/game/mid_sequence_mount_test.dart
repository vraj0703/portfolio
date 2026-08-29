import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/game/backdrop_component.dart';
import 'package:portfolio/presentation/game/logo_layer.dart';
import 'package:portfolio/presentation/game/title_layer_component.dart';

void main() {
  // Every stage the scene can be in when a fresh game is mounted into it.
  const stages = <SceneState>[
    SceneState.loading(),
    SceneState.logo(),
    SceneState.logoOverlayRemoving(),
    SceneState.titleLoading(),
    SceneState.title(),
    SceneState.active(),
    SceneState.gallery(),
    SceneState.contact(),
  ];

  group('mounting part-way through the sequence', () {
    // Leaving the gallery rebuilds the Flame game directly into the title
    // stage, so no component ever sees the transition that got the scene
    // there. Each of these keyed its behaviour off a transition that was by
    // then long past, so nothing ran: the mark sat centred and full size, the
    // backdrop never rose, the title never started — and the result read as
    // having been dropped back at the logo screen.

    test('the mark is retreated for every stage past the logo', () {
      for (final stage in stages) {
        // `showsMark` rather than a list spelled out here. The contact
        // screen joined that composition later, and a list would have gone
        // on describing the stages it had when it was written.
        expect(
          LogoMarkComponent.hasRetreatedBy(stage),
          !stage.showsMark,
          reason: '$stage',
        );
      }
    });

    test('the backdrop is up for every stage past the logo', () {
      for (final stage in stages) {
        expect(
          BackdropComponent.hasRisenBy(stage),
          !stage.showsMark,
          reason: '$stage',
        );
      }
    });

    test('the title has begun by every stage it is visible in', () {
      for (final stage in stages) {
        final shows = stage.maybeWhen(
          titleLoading: () => true,
          title: () => true,
          active: (_, _) => true,
          orElse: () => false,
        );
        expect(
          TitleLayerComponent.hasBegunBy(stage),
          shows,
          reason: '$stage',
        );
      }
    });

    test('the stage the gallery hands back to starts all three', () {
      // The one that matters: what `galleryExited` emits.
      const landing = SceneState.titleLoading();

      expect(LogoMarkComponent.hasRetreatedBy(landing), isTrue);
      expect(BackdropComponent.hasRisenBy(landing), isTrue);
      expect(TitleLayerComponent.hasBegunBy(landing), isTrue);
    });
  });
}
