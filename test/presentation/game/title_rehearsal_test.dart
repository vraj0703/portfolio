import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/models/loading_phase.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/game/backdrop_component.dart';
import 'package:portfolio/presentation/screen/my_game.dart';
import 'package:portfolio/presentation/screen/rehearsal_pixel.dart';

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

  group(
    'the rehearsal is drawn through one pixel, over the loading screen',
    () {
      test('last in the scene, and only while loading', () {
        // Under the opaque loading screen the draws never reached the GPU;
        // drawn last, they are the screen's own draws (GL census, ROG).
        final source = File(
          'lib/presentation/screen/scene_view.dart',
        ).readAsStringSync();
        final pixel = source.indexOf('if (isLoading) const RehearsalPixel()');
        expect(pixel, greaterThan(0));
        expect(pixel, greaterThan(source.indexOf('LoadingScreen(')));
        expect(pixel, greaterThan(source.indexOf('ClipPath(')));
      });

      test('inside a plain rect clip of one physical pixel, no layer', () {
        // A rect clip is a scissor: the program stays the real draw's. A
        // saveLayer or an alpha would change the program.
        final source = File(
          'lib/presentation/screen/rehearsal_pixel.dart',
        ).readAsStringSync();
        expect(source, contains('clipRect(Rect.fromLTWH(0, 0, pixel, pixel))'));
        expect(source, contains('1 / View.of(context).devicePixelRatio'));
        expect(source, isNot(contains('saveLayer')));
        expect(source, isNot(contains('Opacity')));
      });

      testWidgets('and paints nothing before there is a game', (tester) async {
        MyGame.stage.value = null;
        await tester.pumpWidget(
          const Directionality(
            textDirection: TextDirection.ltr,
            child: RehearsalPixel(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);
      });
    },
  );
}
