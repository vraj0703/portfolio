import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/data/di/dependency_manager.dart';
import 'package:portfolio/data/di/injection.dart';
import 'package:portfolio/domain/audio/app_audio.dart';
import 'package:portfolio/domain/radio/radio_player.dart';
import 'package:portfolio/domain/style/strings.dart';
import 'package:portfolio/presentation/bloc/menu_drawer_cubit.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/gallery/gallery_exit_requests.dart';
import 'package:portfolio/presentation/menu/menu_drawer.dart';
import 'package:portfolio/presentation/menu/title_actions.dart';

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
    scene = SceneBloc(audio: audio)..emit(state);
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
            children: <Widget>[TitleActions(), MenuDrawer()],
          ),
        ),
      ),
    );
  }

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(host(state: const SceneState.title()));
    await tester.tap(find.byType(MenuButton));
    await tester.pumpAndSettle();
  }

  group('opening and closing', () {
    testWidgets('a press opens the panel', (tester) async {
      await tester.pumpWidget(host(state: const SceneState.title()));

      expect(find.text(strings.menuClose), findsNothing);

      await tester.tap(find.byType(MenuButton));
      await tester.pumpAndSettle();

      expect(find.text(strings.menuClose), findsOneWidget);
      expect(drawer!.state, isTrue);
    });

    testWidgets('escape closes it', (tester) async {
      await open(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(drawer!.state, isFalse);
      expect(find.text(strings.menuClose), findsNothing);
    });

    testWidgets('and so does its own way out', (tester) async {
      await open(tester);

      await tester.tap(find.text(strings.menuClose));
      await tester.pumpAndSettle();

      expect(drawer!.state, isFalse);
      expect(audio.played.last, AudioCue.previous);
    });

    testWidgets('and it leaves before it is taken off the tree', (
      tester,
    ) async {
      // The panel animates out. Dismissing the cubit first would take it off
      // instantly, which is vanishing rather than leaving — so the state
      // must still read open partway through the exit.
      await open(tester);

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

  group('what the panel no longer holds', () {
    testWidgets('neither the sound switch nor the way to contact', (
      tester,
    ) async {
      // Both moved up beside the control that opens the panel. A copy left
      // behind in here would be two switches for one mute, and the one in
      // the panel would be the one nobody finds.
      await open(tester);

      final panel = find.byType(MenuDrawer);

      for (final word in <String>[
        strings.menuSoundOn,
        strings.menuSoundOff,
        strings.menuConnect,
      ]) {
        expect(
          find.descendant(of: panel, matching: find.text(word)),
          findsNothing,
          reason: 'the panel still carries "$word"',
        );
      }

      expect(
        find.descendant(of: panel, matching: find.byType(SvgPicture)),
        findsNothing,
        reason: 'the panel still draws a row mark',
      );
      expect(
        find.descendant(of: panel, matching: find.text(strings.menuClose)),
        findsOneWidget,
      );
    });
  });

  group('in the gallery', () {
    late RecordingRadio radio;

    setUp(() {
      radio = RecordingRadio();
      DependencyManager.instance.registerSingleton<RadioPlayer>(radio);
    });

    tearDown(() => radio.dispose());

    Future<void> openIn(WidgetTester tester, SceneState state) async {
      await tester.pumpWidget(host(state: state));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(MenuButton));
      await tester.pumpAndSettle();
    }

    testWidgets("the title's three icons stay, the same widget", (
      tester,
    ) async {
      await tester.pumpWidget(host(state: const SceneState.gallery()));
      await tester.pumpAndSettle();
      expect(find.byType(SoundButton), findsOneWidget);
      expect(find.byType(ConnectButton), findsOneWidget);
      expect(find.byType(MenuButton), findsOneWidget);
      // Past the gallery's delayed radio start.
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('the drawer holds the radio: play, stop, next', (tester) async {
      await openIn(tester, const SceneState.gallery());
      expect(find.text(strings.drawerRadioNext), findsOneWidget);

      await tester.tap(find.text(strings.drawerRadioPlay));
      await tester.pumpAndSettle();
      expect(radio.calls, <String>['play']);
      expect(find.text(strings.drawerRadioStop), findsOneWidget);

      await tester.tap(find.text(strings.drawerRadioNext));
      await tester.pumpAndSettle();
      expect(radio.calls.last, 'next');
    });

    testWidgets("and the way out, through the gallery's own exit", (
      tester,
    ) async {
      var asked = 0;
      void count() => asked++;
      GalleryExitRequests.instance.addListener(count);
      addTearDown(() => GalleryExitRequests.instance.removeListener(count));

      await openIn(tester, const SceneState.gallery());
      await tester.tap(find.text(strings.drawerLeaveGallery));
      await tester.pumpAndSettle();

      expect(asked, 1);
      expect(drawer!.state, isFalse, reason: 'the drawer closes first');
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('on the title the drawer holds no radio', (tester) async {
      await openIn(tester, const SceneState.title());
      expect(find.text(strings.drawerRadioNext), findsNothing);
      expect(find.text(strings.drawerLeaveGallery), findsNothing);
    });
  });
}
