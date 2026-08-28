import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/models/loading_phase.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';

void main() {
  test('the logo stays interactive even if its entrance finishes early',
      () async {
    // The overlay advances its entrance from the moment it mounts and reports
    // completion exactly once. Loading is what decides whether that report
    // lands before or after the scene reaches the logo — so if loading takes
    // longer than the 1.4s entrance, the only report there will ever be
    // arrives while the state is still Loading.
    final bloc = SceneBloc()..add(const SceneEvent.initialize());
    await Future<void>.delayed(Duration.zero);

    bloc.add(const SceneEvent.logoEntranceCompleted());
    await Future<void>.delayed(Duration.zero);

    for (final phase in LoadingPhase.values) {
      bloc.add(SceneEvent.loadingProgressed(phase: phase, value: 1));
    }
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state, isA<Logo>(), reason: 'precondition');
    expect(
      (bloc.state as Logo).isInteractive,
      isTrue,
      reason: 'a logo screen that never becomes interactive ignores every '
          'tap and every key press for the rest of the visit',
    );

    await bloc.close();
  });
}
