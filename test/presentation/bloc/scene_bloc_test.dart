import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/models/loading_phase.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';

void main() {
  late SceneBloc bloc;

  setUp(() => bloc = SceneBloc());
  tearDown(() => bloc.close());

  /// Drives every phase to completion, which is what releases the scene.
  Future<void> completeAllPhases() async {
    for (final phase in LoadingPhase.values) {
      bloc.add(SceneEvent.loadingProgressed(phase: phase, value: 1));
    }
    await Future<void>.delayed(Duration.zero);
  }

  /// Waits for the scene to leave loading.
  ///
  /// Checks the current state before subscribing: the transition may be
  /// emitted synchronously with the final report, in which case waiting on
  /// the stream alone would hang on a state that has already gone past.
  /// Written this way so it holds whether or not the bloc delays the reveal.
  Future<void> awaitReveal() async {
    if (bloc.state is Logo) return;
    await bloc.stream
        .firstWhere((state) => state is Logo)
        .timeout(const Duration(seconds: 10));
  }

  group('SceneBloc', () {
    test('starts in loading with nothing reported', () {
      expect(bloc.state, isA<Loading>());
      expect((bloc.state as Loading).progress.value, 0);
    });

    test('folds a progress report into the loading state', () async {
      final phase = LoadingPhase.values.first;
      bloc.add(SceneEvent.loadingProgressed(phase: phase, value: 0.5));
      await Future<void>.delayed(Duration.zero);

      final state = bloc.state;
      expect(state, isA<Loading>());
      expect((state as Loading).progress.of(phase), closeTo(0.5, 1e-9));
    });

    test('leaves loading for logo once every phase completes', () async {
      await completeAllPhases();
      await awaitReveal();
      expect(bloc.state, isA<Logo>());
    });


    test('stays in loading while any phase is short', () async {
      for (final phase in LoadingPhase.values) {
        bloc.add(SceneEvent.loadingProgressed(phase: phase, value: 0.99));
      }
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<Loading>());
    });

    test('emits the completed bar before revealing', () async {
      // The UI should get a chance to paint 100%, not jump from 99 to gone.
      final seen = <SceneState>[];
      final sub = bloc.stream.listen(seen.add);

      await completeAllPhases();
      await awaitReveal();
      await sub.cancel();

      final lastLoading = seen.whereType<Loading>().last;
      expect(lastLoading.progress.isComplete, isTrue);
      expect(seen.last, isA<Logo>());
    });

    test('ignores a report that does not advance its phase', () async {
      final phase = LoadingPhase.values.first;
      bloc.add(SceneEvent.loadingProgressed(phase: phase, value: 0.6));
      await Future<void>.delayed(Duration.zero);

      final emitted = <SceneState>[];
      final sub = bloc.stream.listen(emitted.add);

      bloc.add(SceneEvent.loadingProgressed(phase: phase, value: 0.6));
      bloc.add(SceneEvent.loadingProgressed(phase: phase, value: 0.2));
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(emitted, isEmpty, reason: 'redundant reports must not rebuild');
    });

    test('drops stragglers arriving after the reveal', () async {
      await completeAllPhases();
      await awaitReveal();
      expect(bloc.state, isA<Logo>());

      // A subsystem finishing late must not drag the scene back to loading.
      bloc.add(
        SceneEvent.loadingProgressed(
          phase: LoadingPhase.values.first,
          value: 1,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<Logo>());
    });

    test('queue dispatches through the Queuer interface', () async {
      // Game systems hold a Queuer, not the bloc, so this path is the one
      // they actually use.
      final phase = LoadingPhase.values.first;
      bloc.queue(
        event: SceneEvent.loadingProgressed(phase: phase, value: 0.25),
      );
      await Future<void>.delayed(Duration.zero);

      expect((bloc.state as Loading).progress.of(phase), closeTo(0.25, 1e-9));
    });
  });

  group('logo layer', () {
    /// Gets the scene as far as the logo, which is where taps start mattering.
    Future<void> reachLogo() async {
      await completeAllPhases();
      await awaitReveal();
    }

    test('the logo is not interactive until its entrance finishes', () async {
      await reachLogo();
      expect((bloc.state as Logo).isInteractive, isFalse);
    });

    test('becomes interactive once the entrance reports in', () async {
      await reachLogo();
      bloc.add(const SceneEvent.logoEntranceCompleted());
      await Future<void>.delayed(Duration.zero);

      expect((bloc.state as Logo).isInteractive, isTrue);
    });

    test('ignores taps while the entrance is still playing', () async {
      await reachLogo();
      bloc.add(const SceneEvent.tapped());
      await Future<void>.delayed(Duration.zero);

      expect(
        bloc.state,
        isA<Logo>(),
        reason: 'the scene must not be skippable before it is legible',
      );
    });

    test('a tap advances once interactive', () async {
      await reachLogo();
      bloc.add(const SceneEvent.logoEntranceCompleted());
      await Future<void>.delayed(Duration.zero);

      bloc.add(const SceneEvent.tapped());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<LogoOverlayRemoving>());
    });

    test('a second entrance report changes nothing', () async {
      await reachLogo();
      bloc.add(const SceneEvent.logoEntranceCompleted());
      await Future<void>.delayed(Duration.zero);

      final emitted = <SceneState>[];
      final sub = bloc.stream.listen(emitted.add);
      bloc.add(const SceneEvent.logoEntranceCompleted());
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(emitted, isEmpty);
    });

    test('ignores taps while still loading', () async {
      bloc.add(const SceneEvent.tapped());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<Loading>());
    });

    test('ignores a further tap after the layer has begun leaving', () async {
      await reachLogo();
      bloc.add(const SceneEvent.logoEntranceCompleted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const SceneEvent.tapped());
      await Future<void>.delayed(Duration.zero);

      bloc.add(const SceneEvent.tapped());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<LogoOverlayRemoving>());
    });
  });
}
