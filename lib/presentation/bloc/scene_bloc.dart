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
    on<LogoEntranceCompleted>(_onLogoEntranceCompleted);
    on<Tapped>(_onTapped);
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

  FutureOr<void> _onLogoEntranceCompleted(
    LogoEntranceCompleted event,
    Emitter<SceneState> emit,
  ) {
    final current = state;
    if (current is! Logo || current.isInteractive) return null;

    emit(current.copyWith(isInteractive: true));
  }

  FutureOr<void> _onTapped(Tapped event, Emitter<SceneState> emit) {
    final current = state;

    // Only the logo layer consumes taps, and only once it has finished
    // animating in. Anything else is a stray tap on a scene that has no
    // affordance yet.
    if (current is! Logo || !current.isInteractive) return null;

    emit(const SceneState.logoOverlayRemoving());
  }
}
