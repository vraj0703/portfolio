part of 'scene_bloc.dart';

@freezed
class SceneEvent with _$SceneEvent {
  /// Dispatched once when the scene mounts.
  ///
  /// Reserved for work the bloc itself owns (preloading vectors, reading
  /// persisted settings). It currently does nothing — the game reports its
  /// own progress via [SceneEvent.loadingProgressed].
  const factory SceneEvent.initialize() = Initialize;

  /// Reported by a loading subsystem as it advances.
  ///
  /// [value] is that phase's own progress in `0..1`, not a share of the
  /// overall bar — weighting is [LoadingProgress]'s job, so a subsystem never
  /// needs to know what else is loading alongside it.
  const factory SceneEvent.loadingProgressed({
    required LoadingPhase phase,
    required double value,
  }) = LoadingProgressed;

  /// The logo layer has finished animating in and is ready to be tapped.
  ///
  /// Reported by the overlay rather than timed by the bloc: the entrance is
  /// the overlay's own timeline, and gating interaction on a duration the
  /// bloc guesses at would drift the moment that timeline is retuned.
  const factory SceneEvent.logoEntranceCompleted() = LogoEntranceCompleted;

  /// The user tapped the scene.
  const factory SceneEvent.tapped() = Tapped;
}
