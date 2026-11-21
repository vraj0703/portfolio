part of 'scene_bloc.dart';

@freezed
sealed class SceneState with _$SceneState {
  const SceneState._();

  /// Assets and subsystems are still loading; the loading screen is up.
  ///
  /// [progress] carries the per-phase detail rather than a bare double so the
  /// UI can render an overall bar today and a per-phase breakdown later
  /// without another state change.
  const factory SceneState.loading({
    @Default(LoadingProgress.empty) LoadingProgress progress,
    @Default(ButtonFlags()) ButtonFlags flags,
    @Default(false) bool muted,
  }) = Loading;

  /// The mark is on screen with its "tap to enter" affordance.
  ///
  /// [isInteractive] is false while the layer animates in. Taps are ignored
  /// until it flips, so the scene cannot be skipped past before the user has
  /// seen what they are tapping.
  ///
  /// [touchHovered]: a touch's first tap put the logo into the hover a mouse
  /// gets by passing over it (PORTFOLIO-27, Vishal 2026-11-21: "on logo state
  /// for mobile can we have double tap so that user can experience hover").
  /// The logo layer shows it; the next tap enters.
  const factory SceneState.logo({
    @Default(false) bool isInteractive,
    @Default(false) bool touchHovered,
    @Default(ButtonFlags()) ButtonFlags flags,
    @Default(false) bool muted,
  }) = Logo;

  const factory SceneState.logoOverlayRemoving({
    @Default(ButtonFlags()) ButtonFlags flags,
    @Default(false) bool muted,
  }) = LogoOverlayRemoving;

  const factory SceneState.titleLoading({
    @Default(ButtonFlags()) ButtonFlags flags,
    @Default(false) bool muted,
  }) = TitleLoading;

  const factory SceneState.title({
    @Default(ButtonFlags()) ButtonFlags flags,
    @Default(false) bool muted,
  }) = Title;

  const factory SceneState.active({
    @Default(1.0) double uiOpacity,
    @Default(true) bool isArrowVisible,
    @Default(ButtonFlags()) ButtonFlags flags,
    @Default(false) bool muted,
  }) = Active;

  /// The gallery: the corridor of work the bold text hands over to.
  ///
  /// [leavingFor] is set while the visitor is on their way out: the gallery
  /// runs its lights-down, then raises the event that arrives there.
  const factory SceneState.gallery({
    @Default(ButtonFlags()) ButtonFlags flags,
    @Default(false) bool muted,
    GalleryExit? leavingFor,
  }) = Gallery;

  /// The contact screen.
  ///
  /// Presented as the logo screen is — the mark back in the middle of an
  /// empty ground — with the horizontal menu standing where "TAP TO ENTER"
  /// stands. Reusing that stage rather than building a second one is the
  /// point of it: the visitor has seen this composition before, and meeting
  /// it again reads as arriving somewhere rather than as a page change.
  const factory SceneState.contact({
    @Default(ButtonFlags()) ButtonFlags flags,
    @Default(false) bool muted,
  }) = Contact;

  /// Whether the mark is the subject of the screen, centred and full size.
  ///
  /// Three stages share the logo screen's composition — the loading curtain,
  /// the logo itself and the contact screen — and the layers that make it up
  /// each used to spell that list out for themselves. Three copies of one
  /// rule is three chances to add a stage to two of them, which is exactly
  /// what shows up as the mark sitting in its corner over a contact screen
  /// with no subject.
  bool get showsMark => this is Loading || this is Logo || this is Contact;

  /// Whether the title stage makes its real draws while loading, through one
  /// pixel over the loading screen (`RehearsalPixel`).
  ///
  /// [Loading] and nothing else: every draw the title stage makes for the
  /// first time is a GPU program CanvasKit compiles on that frame (130-740
  /// ms each on a phone, after the tap). Skia keys a program on the whole
  /// draw, so only the real draw compiles the real program. The components
  /// read this rule; none of them decides for itself when to rehearse.
  /// `MyGame` counts the frames into `LoadingPhase.rehearsal`, so the bar
  /// waits for them.
  bool get rehearsesTitle => this is Loading;

  bool get isScrollable => this is Active || this is Gallery;

  /// Whether a touch in the gallery walks with a thumb stick and looks
  /// around with a drag (WalkControl), rather than dragging the corridor
  /// like a page. The gallery's rule, behind its flag; the view reads it.
  bool get walksByStick => this is Gallery && flags.walkStick;

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
  ///
  /// And in the gallery (Vishal, 2026-11-18): the same three icons in the
  /// same corner, the drawer holding the radio and the way out.
  ///
  /// And on the contact page (PORTFOLIO-24), so the drawer, and its bar's
  /// way home and to the gallery, is reachable from every section.
  bool get showsMenu =>
      this is Title || this is Active || this is Gallery || this is Contact;

  /// The title's Connect and Menu buttons: on the stages that show the
  /// menu, and only while their feature flag (carried by every state, see
  /// [ButtonFlags]) leaves them shown. Widgets read these, never the flag.
  bool get showsMenuButton => showsMenu && flags.menu;

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

  /// Which of the drawer's bar destinations the visitor is at (PORTFOLIO-24):
  /// the title's stages are home, the gallery is the gallery, the contact
  /// page is contact; anything else (loading, the logo) none. The bar keeps
  /// no state of its own; it reads this.
  NavDestination? get navCurrent => switch (this) {
    TitleLoading() || Title() || Active() => NavDestination.home,
    Gallery() => NavDestination.gallery,
    Contact() => NavDestination.contact,
    _ => null,
  };

  /// Where the visitor is leaving the gallery for, while the lights go down
  /// (null when they are not leaving, or not in the gallery). The gallery
  /// view reads it and runs its fade; the bloc is the only one who sets it.
  GalleryExit? get galleryLeavingFor => switch (this) {
    Gallery(:final leavingFor) => leavingFor,
    _ => null,
  };

  /// Whether the screen's chrome (the title's icons) sits on a light scene
  /// and wants the dark ink: the gallery's ceiling, not the title's dusk.
  bool get chromeOnLight => this is Gallery;

  /// Whether a swipe on the title moves it by strokes (one swipe, one timed
  /// move between pauses) rather than by distance. Touch only (the wheel
  /// always scrolls), behind the same flag as the gallery's thumb stick, so
  /// turning the touch controls off restores the old drag everywhere.
  bool get swipesByStroke => flags.walkStick;
}

/// The drawer's bar: where it can take the visitor.
enum NavDestination { home, gallery, contact }

/// Where a visitor leaving the gallery is going: the title (the BACK sign,
/// the drawer) or the contact page (the wall's LET'S CONNECT).
enum GalleryExit { title, contact }
