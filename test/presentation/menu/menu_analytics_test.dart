import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/data/di/dependency_manager.dart';
import 'package:portfolio/data/di/injection.dart';
import 'package:portfolio/domain/analytics/analytics.dart';
import 'package:portfolio/domain/audio/app_audio.dart';
import 'package:portfolio/domain/radio/radio_player.dart';
import 'package:portfolio/presentation/bloc/menu_drawer_cubit.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/menu/menu_drawer.dart';
import 'package:portfolio/presentation/menu/title_actions.dart';

import '../../support/scene_harness.dart';

/// Records what would have been sent.
class Sent implements Analytics {
  final List<(String, Map<String, Object?>)> events =
      <(String, Map<String, Object?>)>[];

  @override
  void capture(
    String event,
    Map<String, Object?> properties, {
    bool beforeUnload = false,
  }) => events.add((event, properties));

  @override
  void screen(String path, Map<String, Object?> properties) {}

  @override
  bool flag(String key, {required bool orElse}) => orElse;

  @override
  Listenable get flagsChanged => ChangeNotifier();

  @override
  void captureException(Object error, StackTrace? stack) {}

  Map<String, Object?> last(String name) =>
      events.lastWhere((e) => e.$1 == name).$2;
}

void main() {
  late Sent sent;
  late RecordingRadio radio;
  SceneBloc? scene;
  MenuDrawerCubit? drawer;

  setUp(() async {
    DependencyManager.instance.reset();
    await initDependencies();
    sent = Sent();
    radio = RecordingRadio();
    DependencyManager.instance
      ..registerSingleton<SiteEvents>(
        SiteEvents(sent, viewport: () => (390, 844)),
      )
      ..registerSingleton<RadioPlayer>(radio);
  });

  tearDown(() async {
    await scene?.close();
    await drawer?.close();
    await radio.dispose();
    DependencyManager.instance.reset();
  });

  Widget host(SceneState state) {
    final audio = RecordingAudio();
    scene = SceneBloc(audio: audio, radio: radio)..emit(state);
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

  testWidgets('menu_opened, with the scene it was opened on', (tester) async {
    await tester.pumpWidget(host(const SceneState.title()));
    await tester.tap(find.byType(MenuButton));
    await tester.pumpAndSettle();
    expect(sent.events.map((e) => e.$1), contains('menu_opened'));
    expect(sent.last('menu_opened'), contains('scene'));
  });

  testWidgets('radio_toggled and radio_station_changed, from the drawer', (
    tester,
  ) async {
    await tester.pumpWidget(host(const SceneState.title()));
    await tester.tap(find.byType(MenuButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('PLAY'));
    await tester.pumpAndSettle();
    expect(sent.last('radio_toggled'), <String, Object?>{
      ...sent.last('radio_toggled'),
      'on': true,
      'surface': 'drawer',
    });

    await tester.tap(find.text('NEXT'));
    await tester.pumpAndSettle();
    final changed = sent.last('radio_station_changed');
    expect(changed['surface'], 'drawer');
    expect(changed['station'], isA<String>());
  });

  test('the wall reports its own surface', () {
    final events = SiteEvents(sent, viewport: () => (390, 844))
      ..radioToggled(on: false, surface: 'wall')
      ..radioStationChanged(station: 'Jazz', surface: 'wall');
    expect(events, isNotNull);
    expect(sent.last('radio_toggled')['surface'], 'wall');
    expect(sent.last('radio_toggled')['on'], false);
    expect(sent.last('radio_station_changed')['station'], 'Jazz');
  });

  test('the new events are in the typed list', () {
    expect(
      SiteEvents.names,
      containsAll(<String>[
        'menu_opened',
        'radio_toggled',
        'radio_station_changed',
      ]),
    );
  });

  test('a radio the visitor put on keeps playing out of the gallery', () async {
    final bloc = SceneBloc(radio: radio)..emit(const SceneState.title());
    addTearDown(bloc.close);
    // The drawer's play, on the title: a press to the bloc.
    bloc.add(const SceneEvent.radioToggled());
    await Future<void>.delayed(Duration.zero);
    expect(radio.calls, <String>['play']);
    bloc.emit(const SceneState.gallery());
    bloc.emit(const SceneState.title());
    await Future<void>.delayed(Duration.zero);
    expect(radio.calls, <String>['play'], reason: 'not stopped on the way');
  });

  test("pressed again, it stops, and is the gallery's again", () async {
    final bloc = SceneBloc(radio: radio)..emit(const SceneState.title());
    addTearDown(bloc.close);
    bloc
      ..add(const SceneEvent.radioToggled())
      ..add(const SceneEvent.radioToggled());
    await Future<void>.delayed(Duration.zero);
    expect(radio.calls, <String>['play', 'stop']);
  });

  test('a radio the gallery put on still goes off as the visitor leaves', () {
    final bloc = SceneBloc(radio: radio);
    addTearDown(bloc.close);
    radio.play();
    bloc.emit(const SceneState.title());
    expect(radio.calls.last, 'stop');
  });
}
