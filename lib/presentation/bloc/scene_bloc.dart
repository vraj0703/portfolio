import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:portfolio/domain/audio/app_audio.dart';
import 'package:portfolio/domain/interfaces/queuer.dart';
import 'package:portfolio/domain/models/loading_phase.dart';
import 'package:portfolio/domain/models/loading_progress.dart';
import 'package:portfolio/domain/radio/radio_player.dart';

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
  SceneBloc({RadioPlayer radio = const SilentRadio()})
    // A named parameter cannot be spelled `_radio`, so the field cannot be
    // an initialising formal here — the lint's suggestion does not compile.
    // ignore: prefer_initializing_formals
    : _radio = radio,
      super(const SceneState.loading()) {
    on<Initialize>(_initialize);
    on<LoadingProgressed>(_onLoadingProgressed);
    on<LogoEntranceCompleted>(_onLogoEntranceCompleted);
    on<Tapped>(_onTapped);
    on<LogoExitCompleted>(_onLogoExitCompleted);
    on<TitleEntranceCompleted>(_onTitleEntranceCompleted);
    on<AdvanceRequested>(_onAdvanceRequested);
    on<BoldTextCompleted>(_onBoldTextCompleted);
    on<GalleryExited>(_onGalleryExited);
    on<ContactRequested>(_onContactRequested);
    on<GalleryRequested>(_onGalleryRequested);
    on<HomeRequested>(_onHomeRequested);
  }

  /// The wall radio, which the scene owns rather than the corridor does.
  ///
  /// It used to be started by the gallery view, on the reasoning that the
  /// radio is on the gallery's walls. But *when it plays* is a fact about
  /// which screen the visitor is on, and the only thing that knows that is
  /// this — so the view was answering a question it could only see half of,
  /// and the radio went on playing under whatever came next.
  final RadioPlayer _radio;

  /// The wait between arriving in the corridor and the radio coming on.
  Timer? _tuningIn;

  @override
  void queue({required SceneEvent event}) => add(event);

  /// Puts the radio on air, or takes it off, to suit [state].
  ///
  /// Hung off [onChange] rather than written into each handler: there are
  /// four ways out of the gallery and more will be added, and a rule that
  /// has to be remembered at every one of them is a rule that will be
  /// forgotten at the next.
  @override
  void onChange(Change<SceneState> change) {
    super.onChange(change);

    final state = change.nextState;
    if (state.playsRadio) {
      _tuneIn();
    } else {
      _tuneOut();
    }
  }

  void _tuneIn() {
    // Already coming, or already here. Re-entering the corridor from the
    // contact screen must not stack a second wait on the first.
    if (_tuningIn != null) return;
    if (_radio.state.isPlaying || _radio.state.isTuning) return;

    // After the room has finished announcing itself. Arriving in the
    // corridor plays [AudioCue.galleryEntry], and music starting underneath
    // it makes the arrival sound like a mistake — so the wait *is* that
    // cue's length, taken from the cue rather than guessed, so the two stay
    // in step if the sound is ever replaced.
    _tuningIn = Timer(AudioCue.galleryEntry.length, () {
      _tuningIn = null;

      // Checked again on the way out of the wait, not only on the way in.
      // The visitor may have pressed PLAY on the wall while it ran.
      if (_radio.state.isPlaying || _radio.state.isTuning) return;
      unawaited(_radio.play());
    });
  }

  void _tuneOut() {
    // Cancelled first. Leaving the corridor before the music has started
    // must not leave a timer that turns it on over the screen after it.
    _tuningIn?.cancel();
    _tuningIn = null;

    if (_radio.state.status == RadioStatus.off) return;
    unawaited(_radio.stop());
  }

  @override
  Future<void> close() async {
    _tuneOut();
    await super.close();
  }

  /// Whether the logo's entrance has finished, remembered across the arrival
  /// of the state it belongs to.
  ///
  /// The report is fired exactly once, by a component that starts animating
  /// as soon as it mounts — so whether it lands before or after the scene
  /// reaches [Logo] depends entirely on how long loading took. Dropping it
  /// for arriving early meant the logo screen never became interactive, and
  /// every tap and key press for the rest of the visit was ignored.
  bool _logoEntranceDone = false;

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
      // Carries a report that arrived while the loading screen was still up,
      // rather than waiting for a second one that will never come.
      emit(SceneState.logo(isInteractive: _logoEntranceDone));
    }
  }

  FutureOr<void> _onLogoEntranceCompleted(
    LogoEntranceCompleted event,
    Emitter<SceneState> emit,
  ) {
    _logoEntranceDone = true;

    final current = state;
    if (current is! Logo || current.isInteractive) return null;

    emit(current.copyWith(isInteractive: true));
  }

  FutureOr<void> _onGalleryExited(
    GalleryExited event,
    Emitter<SceneState> emit,
  ) {
    // Guarded like every other transition: the sign lives in the gallery, so
    // an event from anywhere else is a stray one.
    if (state is! Gallery) return null;

    // `title`, not `titleLoading`. The game is no longer torn down on the way
    // into the corridor, so the stage is still standing exactly as it was
    // left — replaying its two-second entrance would be animating something
    // the visitor can already see.
    emit(const SceneState.title());
  }

  FutureOr<void> _onContactRequested(
    ContactRequested event,
    Emitter<SceneState> emit,
  ) {
    // The sign hangs in the skills hall, so the gallery is the only place it
    // can be pressed from.
    if (state is! Gallery) return null;
    emit(const SceneState.contact());
  }

  FutureOr<void> _onGalleryRequested(
    GalleryRequested event,
    Emitter<SceneState> emit,
  ) {
    if (state is! Contact) return null;

    // The corridor's view is rebuilt from scratch on the way in — it is
    // unmounted while the contact screen is up — so it comes back at the
    // entrance with a fresh scroll, which is what the mark promises.
    emit(const SceneState.gallery());
  }

  FutureOr<void> _onHomeRequested(
    HomeRequested event,
    Emitter<SceneState> emit,
  ) {
    if (state is! Contact) return null;

    // The same door the visitor came in through, not a shortcut past it.
    // The contact screen borrows the logo screen's composition, so leaving
    // it is the logo screen's exit: the mark retreats to its corner, the
    // ground rises and the affordance retracts, and `logoExitCompleted`
    // carries the scene on to the title's entrance. Emitting `titleLoading`
    // here instead would land on a stage none of that had happened to.
    emit(const SceneState.logoOverlayRemoving());
  }

  FutureOr<void> _onTapped(Tapped event, Emitter<SceneState> emit) {
    final current = state;

    // Only the logo layer consumes taps, and only once it has finished
    // animating in. Anything else is a stray tap on a scene that has no
    // affordance yet.
    if (current is! Logo || !current.isInteractive) return null;

    emit(const SceneState.logoOverlayRemoving());
  }

  FutureOr<void> _onLogoExitCompleted(
    LogoExitCompleted event,
    Emitter<SceneState> emit,
  ) {
    if (state is! LogoOverlayRemoving) return null;
    emit(const SceneState.titleLoading());
  }

  FutureOr<void> _onTitleEntranceCompleted(
    TitleEntranceCompleted event,
    Emitter<SceneState> emit,
  ) {
    if (state is! TitleLoading) return null;
    emit(const SceneState.title());
  }

  FutureOr<void> _onAdvanceRequested(
    AdvanceRequested event,
    Emitter<SceneState> emit,
  ) {
    // Only the settled title offers a way onward. Arriving earlier means the
    // user scrolled through the intro, which should not skip it.
    if (state is! Title) return null;
    emit(const SceneState.active());
  }

  FutureOr<void> _onBoldTextCompleted(
    BoldTextCompleted event,
    Emitter<SceneState> emit,
  ) {
    if (state is! Active) return null;
    emit(const SceneState.gallery());
  }
}
