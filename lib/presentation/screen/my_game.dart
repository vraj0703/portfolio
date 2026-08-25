import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:portfolio/domain/interfaces/queuer.dart';
import 'package:portfolio/domain/models/loading_phase.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';

class MyGame extends FlameGame
    with
        ScrollDetector,
        TapCallbacks,
        PointerMoveCallbacks,
        MouseMovementDetector,
        HoverCallbacks {
  MyGame({required this.queuer});

  /// Dispatches into the scene's state machine.
  ///
  /// Deliberately the narrow [Queuer] interface rather than the bloc itself —
  /// the game only ever pushes events, and this keeps it testable with a
  /// recording double.
  final Queuer queuer;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // The game owns no assets yet, so it reports straight to done. As
    // components and audio arrive, report intermediate figures here — the
    // bar is weighted and normalised in LoadingProgress, so this only ever
    // needs to describe the game's own completion, never its share of the
    // overall load.
    _report(1);
  }

  void _report(double value) => queuer.queue(
    event: SceneEvent.loadingProgressed(phase: LoadingPhase.game, value: value),
  );
}
