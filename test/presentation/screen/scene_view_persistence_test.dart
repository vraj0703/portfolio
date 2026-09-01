import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/data/di/dependency_manager.dart';
import 'package:portfolio/data/di/injection.dart';
import 'package:portfolio/domain/models/loading_phase.dart';
import 'package:portfolio/presentation/bloc/menu_drawer_cubit.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/screen/scene_view.dart';

void main() {
  SceneBloc? created;

  setUp(() async {
    DependencyManager.instance.reset();
    await initDependencies();
  });

  tearDown(() async {
    await created?.close();
    created = null;
    DependencyManager.instance.reset();
  });

  Widget host() {
    created = SceneBloc();
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<SceneBloc>.value(value: created!),
          // The scene now carries the title screen's drawer, and the drawer
          // reads its own cubit. Provided here rather than made optional in
          // the widget: a panel that silently does nothing when its state is
          // missing hides exactly the wiring mistake this would catch.
          BlocProvider<MenuDrawerCubit>(create: (_) => MenuDrawerCubit()),
        ],
        child: const Scaffold(body: SceneView()),
      ),
    );
  }

  testWidgets('the game survives a trip through the gallery', (tester) async {
    // The game must not be torn down on the way in. Every component in it
    // keys its behaviour off state *transitions*, so one rebuilt on the way
    // back mounts into a stage it never saw arrive and does nothing at all:
    // the title never starts, the mark never retreats, and the visitor lands
    // on what looks like the logo screen.
    // Matched by predicate: `GameWidget.controlled` returns a generic
    // `GameWidget<MyGame>`, which `byType(GameWidget)` does not find.
    final game = find.byWidgetPredicate((w) => w is GameWidget);

    await tester.pumpWidget(host());
    created!.add(const SceneEvent.initialize());
    for (final phase in LoadingPhase.values) {
      created!.add(SceneEvent.loadingProgressed(phase: phase, value: 1));
    }
    await tester.pump();
    expect(game, findsOneWidget, reason: 'precondition');

    // The element, not the widget: the widget object is rebuilt on every
    // build and comparing those would pass whether or not the game survived.
    // The element is what owns the state, and the game with it.
    final before = tester.element(game);

    created!.add(const SceneEvent.galleryExited());
    await tester.pump();

    expect(game, findsOneWidget, reason: 'the game was torn down');
    expect(
      tester.element(game),
      same(before),
      reason: 'the game was rebuilt rather than kept',
    );
  });
}
