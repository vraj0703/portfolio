import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/core/di/dependency_manager.dart';
import 'package:portfolio/core/di/injection.dart';
import 'package:portfolio/domain/models/loading_phase.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/screen/my_game.dart';
import 'package:portfolio/presentation/screen/scene_view.dart';
import 'package:portfolio/presentation/widgets/curtain_clipper.dart';
import 'package:portfolio/presentation/widgets/loading_screen.dart';

void main() {
  SceneBloc? created;

  setUp(() async {
    DependencyManager.instance.reset();
    await initDependencies();
  });

  tearDown(() async {
    // Nullable rather than `late`: not every case builds the scene.
    await created?.close();
    created = null;
    DependencyManager.instance.reset();
  });

  /// Builds the scene, creating the bloc *inside* the test body.
  ///
  /// Deliberately not in `setUp`: that runs outside the test's fake-async
  /// zone, so a bloc created there delivers its state changes on the real
  /// clock and `tester.pump()` never flushes them — the widget then sits on a
  /// stale state while `created!.state` reads correctly, which is a thoroughly
  /// confusing way to fail.
  Widget host() {
    created = SceneBloc();
    return MaterialApp(
      home: BlocProvider<SceneBloc>.value(
        value: created!,
        child: const Scaffold(body: SceneView()),
      ),
    );
  }

  /// The curtain's current opening, 0 = closed, 1 = fully open.
  double revealOf(WidgetTester tester) {
    final clipPath = tester.widget<ClipPath>(find.byType(ClipPath).first);
    return (clipPath.clipper! as CurtainClipper).revealProgress;
  }

  testWidgets('is stateless', (tester) async {
    // The project rule: no StatefulWidget until one is genuinely required.
    // The curtain is an implicit animation and GameWidget.controlled owns the
    // game, so nothing here needs State.
    expect(const SceneView(), isA<StatelessWidget>());
  });

  testWidgets('covers the scene and shows the loading screen while loading',
      (tester) async {
    // First frame only. The game reports its phase done from onLoad, so by
    // the following frame the scene has already left loading — the state
    // machine's own transitions are covered in scene_bloc_test.
    await tester.pumpWidget(host());

    expect(find.byType(LoadingScreen), findsOneWidget);
    expect(revealOf(tester), 0, reason: 'curtain must start fully closed');

    // Let the game finish so no work is left pending at teardown.
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('hosts the game beneath the curtain', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump();

    expect(find.byType(GameWidget<MyGame>), findsOneWidget);
  });

  testWidgets('opens the curtain and clears the loading screen once loaded',
      (tester) async {
    await tester.pumpWidget(host());

    // Drive the phases from inside the test's async zone rather than waiting
    // on the real game to finish loading. The game reports the same events a
    // moment later anyway (the bloc drops them as stragglers), but waiting on
    // it would mean stepping outside the fake clock, and a live Flame ticker
    // does not hand control back cleanly when you do.
    for (final phase in LoadingPhase.values) {
      created!.add(SceneEvent.loadingProgressed(phase: phase, value: 1));
    }

    await tester.pump(); // events processed
    await tester.pump(); // state lands, reveal tween starts

    expect(created!.state, isA<Logo>());

    // Drive frames until the reveal finishes rather than assuming a count.
    for (var i = 0; i < 40 && revealOf(tester) < 1; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(revealOf(tester), 1, reason: 'curtain should be fully open');
    expect(
      find.byType(LoadingScreen),
      findsNothing,
      reason: 'a fully revealed scene should not keep paying for the curtain',
    );
  });

  testWidgets('does not rebuild the game when progress changes',
      (tester) async {
    await tester.pumpWidget(host());
    await tester.pump();

    final before = tester.widget<GameWidget<MyGame>>(
      find.byType(GameWidget<MyGame>),
    );

    created!.add(
      SceneEvent.loadingProgressed(
        phase: LoadingPhase.values.first,
        value: 0.5,
      ),
    );
    await tester.pump();

    final after = tester.widget<GameWidget<MyGame>>(
      find.byType(GameWidget<MyGame>),
    );

    // The GameWidget sits outside the BlocBuilder precisely so a progress
    // tick cannot churn it.
    expect(identical(before, after), isTrue);
  });

  testWidgets('a click on the logo screen advances the scene', (tester) async {
    // The composition, not SceneInput alone: what sits under the pointer here
    // is the whole stack — curtain, loading screen, GameWidget — and the
    // question is whether a click survives all of it.
    await tester.pumpWidget(host());
    created!.add(const SceneEvent.initialize());
    for (final phase in LoadingPhase.values) {
      created!.add(SceneEvent.loadingProgressed(phase: phase, value: 1));
    }
    await tester.pump();
    created!.add(const SceneEvent.logoEntranceCompleted());
    await tester.pump();

    expect(created!.state, isA<Logo>(), reason: 'precondition');

    await tester.tapAt(const Offset(400, 300));
    await tester.pump();

    expect(created!.state, isNot(isA<Logo>()));
  });
}