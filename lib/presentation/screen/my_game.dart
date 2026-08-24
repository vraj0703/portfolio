import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:projects/domain/interfaces/queuer.dart';
import 'package:projects/presentation/bloc/scene_bloc.dart';

class MyGame extends FlameGame
    with
        ScrollDetector,
        TapCallbacks,
        PointerMoveCallbacks,
        MouseMovementDetector,
        HoverCallbacks {
  @override
  final Queuer queuer;
  final SceneBloc _bloc;

  /// Loading progress (0.0–1.0) exposed for the overlay widget.
  final ValueNotifier<double> loadingProgress = ValueNotifier(0.0);

  MyGame({required SceneBloc bloc}) : _bloc = bloc, queuer = bloc;
}
