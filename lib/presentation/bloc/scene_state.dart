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

  /// The contact screen.
  ///
  /// Presented as the logo screen is — the mark back in the middle of an
  /// empty ground — with the horizontal menu standing where "TAP TO ENTER"
  /// stands. Reusing that stage rather than building a second one is the
  /// point of it: the visitor has seen this composition before, and meeting
  /// it again reads as arriving somewhere rather than as a page change.
  const factory SceneState.contact() = Contact;

  /// Whether the mark is the subject of the screen, centred and full size.
  ///
  /// Three stages share the logo screen's composition — the loading curtain,
  /// the logo itself and the contact screen — and the layers that make it up
  /// each used to spell that list out for themselves. Three copies of one
  /// rule is three chances to add a stage to two of them, which is exactly
  /// what shows up as the mark sitting in its corner over a contact screen
  /// with no subject.
  bool get showsMark => this is Loading || this is Logo || this is Contact;

  bool get isScrollable => this is Active || this is Gallery;

  bool get isInteractable => this is Logo || this is Title;

  /// Whether the title screen's menu control belongs on screen.
  ///
  /// The two stages with no other way out. The logo screen offers "TAP TO
  /// ENTER" and nothing else on purpose, the corridor has its signs cut into
  /// the walls, and the contact screen *is* a menu — so those are the only
  /// two that need one.
  ///
  /// A rule on the state rather than a check at the widget, like the two
  /// below it: `Title` is also a Flutter widget, and a view that tests for
  /// it directly has to fight its own imports to say so.
  bool get showsMenu => this is Title || this is Active;

  /// Whether the wall radio belongs on air.
  ///
  /// [Gallery] and nothing else. That one state covers the corridor *and*
  /// the skills hall — the hall is walked to, not navigated to — so both
  /// rooms with a radio on the wall are the same answer, and the screens
  /// with no radio anywhere on them are all the other one.
  ///
  /// A rule rather than a check at each call site, because the failure it
  /// prevents is silent: a stage added later that forgets to switch the
  /// radio off leaves a stream playing under a title screen, and nothing
  /// about that looks wrong in the code that added the stage.
  bool get playsRadio => this is Gallery;
}
