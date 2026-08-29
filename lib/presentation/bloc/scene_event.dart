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

  /// The logo layer has finished leaving: the mark has settled into its
  /// corner and the affordance has fully un-typed.
  ///
  /// Both have to finish, and they are independent timelines — whichever
  /// lands first must not pull the scene forward, or the title enters over
  /// leftover glyphs.
  const factory SceneEvent.logoExitCompleted() = LogoExitCompleted;

  /// The titles have finished animating in.
  const factory SceneEvent.titleEntranceCompleted() = TitleEntranceCompleted;

  /// The user asked to move on from the title.
  ///
  /// Raised by either affordance — clicking the arrow or scrolling — because
  /// they mean the same thing. Keeping them as one event stops the two paths
  /// drifting apart, and stops the scene caring which one the user used.
  const factory SceneEvent.advanceRequested() = AdvanceRequested;

  /// The bold-text stage has played out and the scroll is spent.
  const factory SceneEvent.boldTextCompleted() = BoldTextCompleted;

  /// The visitor asked to leave the gallery, from the sign on the left wall.
  ///
  /// Returns them to the title rather than to the bold-text stage they
  /// scrolled through to get here: that stage is a one-way passage driven by
  /// a scroll that has already been spent, and dropping someone back into
  /// the middle of it would strand them halfway through an animation.
  const factory SceneEvent.galleryExited() = GalleryExited;

  /// The visitor pressed the sign on the skills hall's entry wall.
  const factory SceneEvent.contactRequested() = ContactRequested;

  /// They chose the gallery mark on the contact menu.
  ///
  /// Distinct from [SceneEvent.contactRequested]'s inverse: this puts them
  /// back at the *entrance*, not at the skills hall they came from. The
  /// gallery is a walk, and the mark offers to take it again.
  const factory SceneEvent.galleryRequested() = GalleryRequested;

  /// They chose the home mark.
  const factory SceneEvent.homeRequested() = HomeRequested;
}
