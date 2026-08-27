part of 'scene_bloc.dart';

@freezed
class SceneState with _$SceneState {
  const SceneState._();

  /// Assets and subsystems are still loading; the loading screen is up.
  ///
  /// [progress] carries the per-phase detail rather than a bare double so the
  /// UI can render an overall bar today and a per-phase breakdown later
  /// without another state change.
  const factory SceneState.loading({
    @Default(LoadingProgress.empty) LoadingProgress progress,
  }) = Loading;

  /// The mark is on screen with its "tap to enter" affordance.
  ///
  /// [isInteractive] is false while the layer animates in. Taps are ignored
  /// until it flips, so the scene cannot be skipped past before the user has
  /// seen what they are tapping.
  const factory SceneState.logo({@Default(false) bool isInteractive}) = Logo;

  const factory SceneState.logoOverlayRemoving() = LogoOverlayRemoving;

  const factory SceneState.titleLoading() = TitleLoading;

  const factory SceneState.title() = Title;

  const factory SceneState.active({
    @Default(1.0) double uiOpacity,
    @Default(true) bool isArrowVisible,
  }) = Active;

  /// The gallery: the corridor of work the bold text hands over to.
  const factory SceneState.gallery() = Gallery;

  bool get isScrollable => this is Active || this is Gallery;

  bool get isInteractable => this is Logo || this is Title;
}
