import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/data/di/dependency_manager.dart';
import 'package:portfolio/data/di/injection.dart';
import 'package:portfolio/domain/audio/app_audio.dart';
import 'package:portfolio/domain/radio/radio_player.dart';
import 'package:portfolio/domain/style/strings.dart';
import 'package:portfolio/presentation/bloc/menu_drawer_cubit.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/bloc/sound_cubit.dart';
import 'package:portfolio/presentation/menu/menu_drawer.dart';
import 'package:portfolio/presentation/menu/title_actions.dart';

import '../../support/scene_harness.dart';

/// A [RecordingRadio] that also remembers the last volume it was set to,
/// which is how the mute reaches the radio.
class _VolumeRadio extends RecordingRadio {
  double? volume;

  @override
  Future<void> setVolume(double volume) async => this.volume = volume;
}

void main() {
  const strings = DefaultAppStrings();

  SceneBloc? scene;
  MenuDrawerCubit? drawer;
  SoundCubit? sound;
  late RecordingAudio audio;
  late _VolumeRadio radio;

  setUp(() async {
    DependencyManager.instance.reset();
    await initDependencies();
    audio = RecordingAudio();
    radio = _VolumeRadio();
  });

  tearDown(() async {
    await scene?.close();
    await drawer?.close();
    await sound?.close();
    scene = null;
    drawer = null;
    sound = null;
    DependencyManager.instance.reset();
  });

  Widget host({required SceneState state}) {
    scene = SceneBloc()..emit(state);
    drawer = MenuDrawerCubit();
    sound = SoundCubit(audio: audio, radio: radio);

    return MaterialApp(
      theme: ThemeData(
        extensions: <ThemeExtension<dynamic>>[AppAudioExtension(audio: audio)],
      ),
      home: MultiBlocProvider(
        providers: [
          BlocProvider<SceneBloc>.value(value: scene!),
          BlocProvider<MenuDrawerCubit>.value(value: drawer!),
          BlocProvider<SoundCubit>.value(value: sound!),
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

  final buttons = <Finder>[
    find.byType(SoundButton),
    find.byType(ConnectButton),
    find.byType(MenuButton),
  ];

  group('the row belongs to the screens with no other way out', () {
    testWidgets('all three on the title and the stage after it', (
      tester,
    ) async {
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

        for (final button in buttons) {
          expect(button, findsOneWidget, reason: '$state lost $button');
        }
      }
    });

    testWidgets('and none of them anywhere else', (tester) async {
      await tester.pumpWidget(host(state: const SceneState.title()));

      for (final state in <SceneState>[
        const SceneState.loading(),
        const SceneState.logo(),
        const SceneState.gallery(),
        const SceneState.contact(),
      ]) {
        scene!.emit(state);
        await tester.pump();

        for (final button in buttons) {
          expect(button, findsNothing, reason: '$state drew $button');
        }
      }

      // The corridor sets the radio's wait going; let it run out rather than
      // leave a timer pending past the end of the test.
      scene!.emit(const SceneState.title());
      await tester.pump(AudioCue.galleryEntry.length);
    });
  });

  group('sound', () {
    testWidgets('silences the cues and the radio, and offers the way back', (
      tester,
    ) async {
      await tester.pumpWidget(host(state: const SceneState.title()));

      // The label is the *offer*, not the state: sounding, it offers to turn
      // the sound off.
      expect(audio.isMuted, isFalse);
      expect(find.bySemanticsLabel(strings.menuSoundOff), findsOneWidget);

      await tester.tap(find.byType(SoundButton));
      await tester.pump();

      expect(audio.isMuted, isTrue);
      expect(radio.volume, 0);
      expect(
        find.bySemanticsLabel(strings.menuSoundOn),
        findsOneWidget,
        reason: 'a silent site still offered to silence itself',
      );
      expect(
        audio.played,
        isNot(contains(AudioCue.click)),
        reason: 'the confirmation was swallowed by the silence it confirms',
      );

      await tester.tap(find.byType(SoundButton));
      await tester.pump();

      expect(audio.isMuted, isFalse);
      expect(radio.volume, RadioState.defaultVolume);
      expect(audio.played, contains(AudioCue.click));
      expect(find.bySemanticsLabel(strings.menuSoundOff), findsOneWidget);
    });

    testWidgets('a site already silent comes back silent', (tester) async {
      // The audio backend outlives one mount of the scene.
      audio.setMuted(true);
      await tester.pumpWidget(host(state: const SceneState.title()));

      expect(find.bySemanticsLabel(strings.menuSoundOn), findsOneWidget);
    });
  });

  testWidgets('connect reaches the contact screen without the drawer', (
    tester,
  ) async {
    await tester.pumpWidget(host(state: const SceneState.title()));

    await tester.tap(find.byType(ConnectButton));
    await tester.pumpAndSettle();

    expect(scene!.state, isA<Contact>());
    expect(drawer!.state, isFalse);
    expect(audio.played, contains(AudioCue.pageTurn));
  });

  testWidgets('the menu opens the drawer', (tester) async {
    await tester.pumpWidget(host(state: const SceneState.title()));

    await tester.tap(find.byType(MenuButton));
    await tester.pumpAndSettle();

    expect(drawer!.state, isTrue);
    expect(find.text(strings.menuClose), findsOneWidget);
    expect(audio.played, contains(AudioCue.next));
  });

  testWidgets('each says what it does to a screen reader', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(state: const SceneState.title()));

    for (final label in <String>[
      strings.menuSoundOff,
      strings.menuConnect,
      strings.menuOpen,
    ]) {
      final node = tester.getSemantics(find.bySemanticsLabel(label));
      expect(
        node.flagsCollection.isButton,
        isTrue,
        reason: '"$label" is not announced as a button',
      );
    }

    handle.dispose();
  });

  testWidgets('tab walks sound, connect, menu, and enter presses', (
    tester,
  ) async {
    await tester.pumpWidget(host(state: const SceneState.title()));

    Type? focused() {
      final context = FocusManager.instance.primaryFocus?.context;
      if (context == null) return null;
      for (final type in <Type>[SoundButton, ConnectButton, MenuButton]) {
        final found = switch (type) {
          const (SoundButton) =>
            context.findAncestorWidgetOfExactType<SoundButton>(),
          const (ConnectButton) =>
            context.findAncestorWidgetOfExactType<ConnectButton>(),
          _ => context.findAncestorWidgetOfExactType<MenuButton>(),
        };
        if (found != null) return type;
      }
      return null;
    }

    final order = <Type?>[];
    for (var i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      order.add(focused());
    }

    expect(order, <Type>[SoundButton, ConnectButton, MenuButton]);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(drawer!.state, isTrue, reason: 'enter on the menu did not open it');
  });

  for (final viewport in <Size>[const Size(390, 844), const Size(1440, 900)]) {
    testWidgets('targets of at least 44 that fit at ${viewport.width}', (
      tester,
    ) async {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(host(state: const SceneState.title()));

      for (final button in buttons) {
        final box = tester.getRect(button);
        expect(box.width, greaterThanOrEqualTo(44), reason: '$button');
        expect(box.height, greaterThanOrEqualTo(44), reason: '$button');
        expect(box.left, greaterThanOrEqualTo(0), reason: '$button');
        expect(box.right, lessThanOrEqualTo(viewport.width), reason: '$button');
      }

      // Left to right in the order they are read.
      final lefts = buttons.map((b) => tester.getRect(b).left).toList();
      expect(lefts, orderedEquals(<double>[...lefts]..sort()));

      expect(tester.takeException(), isNull);
    });
  }
}
