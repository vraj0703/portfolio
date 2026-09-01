import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/data/di/dependency_manager.dart';
import 'package:portfolio/data/di/injection.dart';
import 'package:portfolio/domain/audio/app_audio.dart';
import 'package:portfolio/domain/style/strings.dart';
import 'package:portfolio/presentation/bloc/menu_drawer_cubit.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/menu/menu_button.dart';
import 'package:portfolio/presentation/menu/menu_drawer.dart';

import '../../support/scene_harness.dart';

void main() {
  const strings = DefaultAppStrings();

  SceneBloc? scene;
  MenuDrawerCubit? drawer;
  late RecordingAudio audio;

  setUp(() async {
    DependencyManager.instance.reset();
    await initDependencies();
    audio = RecordingAudio();
  });

  tearDown(() async {
    await scene?.close();
    await drawer?.close();
    scene = null;
    drawer = null;
    DependencyManager.instance.reset();
  });

  Widget host({required SceneState state}) {
    scene = SceneBloc()..emit(state);
    drawer = MenuDrawerCubit();

    return MaterialApp(
      theme: ThemeData(
        extensions: <ThemeExtension<dynamic>>[AppAudioExtension(audio: audio)],
      ),
      home: MultiBlocProvider(
        providers: [
          BlocProvider<SceneBloc>.value(value: scene!),
          BlocProvider<MenuDrawerCubit>.value(value: drawer!),
        ],
        child: const Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: <Widget>[MenuButton(), MenuDrawer()],
          ),
        ),
      ),
    );
  }

  group('the control belongs to the screens with no other way out', () {
    testWidgets('it is on the title and the stage after it', (tester) async {
      // One bloc walked through the states, rather than one per state closed
      // inside the test: awaiting `close` in a widget test never returns,
      // because nothing advances the fake clock while it waits.
      await tester.pumpWidget(host(state: const SceneState.title()));

      for (final state in <SceneState>[
        const SceneState.title(),
        const SceneState.active(),
      ]) {
        scene!.emit(state);
        await tester.pump();

        expect(find.byType(MenuButton), findsOneWidget);
        expect(
          find.byType(SvgPicture),
          findsOneWidget,
          reason: '$state should show the mark',
        );
      }
    });

    testWidgets('and nowhere else', (tester) async {
      // The logo screen offers "TAP TO ENTER" and nothing else on purpose,
      // the corridor has its signs cut into the walls, and the contact
      // screen is itself a menu. A control on any of them is a second way to
      // say the same thing, in a place that already says it.
      await tester.pumpWidget(host(state: const SceneState.title()));

      for (final state in <SceneState>[
        const SceneState.loading(),
        const SceneState.logo(),
        const SceneState.gallery(),
        const SceneState.contact(),
      ]) {
        scene!.emit(state);
        await tester.pump();

        expect(
          find.byType(SvgPicture),
          findsNothing,
          reason: '$state drew a menu control it has no use for',
        );
      }

      // The corridor sets the radio's wait going; let it run out rather than
      // leave a timer pending past the end of the test.
      scene!.emit(const SceneState.title());
      await tester.pump(AudioCue.galleryEntry.length);
    });
  });

  group('opening and closing', () {
    testWidgets('a press opens the panel', (tester) async {
      await tester.pumpWidget(host(state: const SceneState.title()));

      expect(find.text(strings.menuConnect), findsNothing);

      await tester.tap(find.byType(MenuButton));
      await tester.pumpAndSettle();

      expect(find.text(strings.menuConnect), findsOneWidget);
      expect(find.text(strings.menuClose), findsOneWidget);
      expect(drawer!.state, isTrue);
    });

    testWidgets('escape closes it', (tester) async {
      await tester.pumpWidget(host(state: const SceneState.title()));
      await tester.tap(find.byType(MenuButton));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(drawer!.state, isFalse);
      expect(find.text(strings.menuConnect), findsNothing);
    });

    testWidgets('and it leaves before it is taken off the tree', (
      tester,
    ) async {
      // The panel animates out. Dismissing the cubit first would take it off
      // instantly, which is vanishing rather than leaving — so the state
      // must still read open partway through the exit.
      await tester.pumpWidget(host(state: const SceneState.title()));
      await tester.tap(find.byType(MenuButton));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump(const Duration(milliseconds: 60));

      expect(
        drawer!.state,
        isTrue,
        reason: 'it was dismissed before the panel had finished leaving',
      );

      await tester.pumpAndSettle();
      expect(drawer!.state, isFalse);
    });
  });

  group('what the panel is for', () {
    testWidgets('the sound switch silences the site and says so', (
      tester,
    ) async {
      await tester.pumpWidget(host(state: const SceneState.title()));
      await tester.tap(find.byType(MenuButton));
      await tester.pumpAndSettle();

      // The label is the *offer*, not the state: sounding, the row offers to
      // turn the sound off.
      expect(audio.isMuted, isFalse);
      expect(find.text(strings.menuSoundOff), findsOneWidget);

      await tester.tap(find.text(strings.menuSoundOff));
      await tester.pumpAndSettle();

      expect(audio.isMuted, isTrue);
      expect(
        find.text(strings.menuSoundOn),
        findsOneWidget,
        reason: 'a silent site still offered to silence itself',
      );

      await tester.tap(find.text(strings.menuSoundOn));
      await tester.pumpAndSettle();

      expect(audio.isMuted, isFalse);
      expect(find.text(strings.menuSoundOff), findsOneWidget);
    });

    testWidgets('and the connect row reaches the contact screen', (
      tester,
    ) async {
      // The transition used to be guarded to the gallery, because the only
      // way in was a sign on the hall wall. This is the second way in, and
      // it starts from a screen the guard used to refuse.
      await tester.pumpWidget(host(state: const SceneState.title()));
      await tester.tap(find.byType(MenuButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text(strings.menuConnect));
      await tester.pumpAndSettle();

      expect(scene!.state, isA<Contact>());
      expect(
        drawer!.state,
        isFalse,
        reason: 'the panel was left open over the screen it moved to',
      );
    });
  });
}
