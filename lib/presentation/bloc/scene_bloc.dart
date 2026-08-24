import 'dart:async';

import 'package:flame/events.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projects/domain/interfaces/queuer.dart';

part 'scene_bloc.freezed.dart';
part 'scene_event.dart';
part 'scene_state.dart';

class SceneBloc extends Bloc<SceneEvent, SceneState> implements Queuer {
  SceneBloc() : super(const SceneState.loading()) {
    on<Initialize>(_initialize);
  }

  @override
  void queue({required SceneEvent event}) {
    add(event);
  }

  FutureOr<void> _initialize(
    Initialize event,
    Emitter<SceneState> emit,
  ) async {}
}
