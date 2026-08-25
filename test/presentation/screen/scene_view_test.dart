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
  late SceneBloc bloc;

  setUp(() async {
    DependencyManager.instance.reset();
    await initDependencies();
    bloc = SceneBloc();
  });

  tearDown(() async {
    await bloc.close();
    DependencyManager.instance.reset();
  });

  Widget host() {
    return MaterialApp(
      home: BlocProvider<SceneBloc>.value(
        value: bloc,
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

    // The game reports its phase complete from onLoad, which drives the bloc
    // out of loading; the curtain reveal follows from the state alone.
    //
    // Explicit pumps rather than pumpAndSettle: a live Flame game renders
    // every frame, so the tree is never quiescent and pumpAndSettle would
    // simply time out.
    // Wait on the real clock: the bloc is constructed in setUp, outside this
    // test's fake-async zone, so pumping does not advance any timer it uses.
    // Checks the current state first, since the transition may already have
    // been emitted by the time we subscribe.
    await tester.runAsync(() async {
      if (bloc.state is Logo) return;
      await bloc.stream
          .firstWhere((state) => state is Logo)
          .timeout(const Duration(seconds: 10));
    });
    expect(bloc.state, isA<Logo>());

    // The reveal tween only starts on the frame the state lands, so it needs
    // a further frame to actually run.
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
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

    bloc.add(
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
}
