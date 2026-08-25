import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:portfolio/domain/interfaces/queuer.dart';
import 'package:portfolio/domain/models/loading_phase.dart';
import 'package:portfolio/domain/models/loading_progress.dart';

part 'scene_bloc.freezed.dart';
part 'scene_event.dart';
part 'scene_state.dart';

/// Owns the scene's lifecycle, from loading through to the interactive title.
///
/// The UI is a pure function of this state — widgets read it and render, they
/// never drive the sequence themselves. Loading subsystems push progress in
/// through [Queuer] without knowing what else is loading or how the bar is
/// weighted.
class SceneBloc extends Bloc<SceneEvent, SceneState> implements Queuer {
  SceneBloc() : super(const SceneState.loading()) {
    on<Initialize>(_initialize);
    on<LoadingProgressed>(_onLoadingProgressed);
  }

  @override
  void queue({required SceneEvent event}) => add(event);

  FutureOr<void> _initialize(
    Initialize event,
    Emitter<SceneState> emit,
  ) async {}

  FutureOr<void> _onLoadingProgressed(
    LoadingProgressed event,
    Emitter<SceneState> emit,
  ) async {
    final current = state;

    // A report arriving after the scene has left loading is a straggler from
    // a subsystem that finished behind the reveal. Harmless; drop it rather
    // than yanking the scene back to the loading screen.
    if (current is! Loading) return null;

    final next = current.progress.advance(event.phase, event.value);

    // `advance` hands back the same instance when the report does not move
    // the phase forward, so this skips a rebuild for redundant reports.
    if (identical(next, current.progress)) return null;

    emit(current.copyWith(progress: next));

    if (next.isComplete) {
      emit(const SceneState.logo());
    }
  }
}
