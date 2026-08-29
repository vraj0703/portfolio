import 'dart:async';
import 'dart:ui' as ui;
import 'dart:ui' show Color;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:portfolio/domain/audio/app_audio.dart';
import 'package:portfolio/domain/config/bold_text_config.dart';
import 'package:portfolio/domain/config/cursor_config.dart';
import 'package:portfolio/domain/config/scene_layers.dart';
import 'package:portfolio/domain/interfaces/queuer.dart';
import 'package:portfolio/domain/models/loading_phase.dart';
import 'package:portfolio/domain/style/scene_palette.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/game/backdrop_component.dart';
import 'package:portfolio/presentation/game/bold_text_component.dart';
import 'package:portfolio/presentation/game/cursor_tracker.dart';
import 'package:portfolio/domain/utils/scroll_driver.dart';
import 'package:portfolio/presentation/game/logo_layer.dart';
import 'package:portfolio/presentation/game/scroll_cue_component.dart';
import 'package:portfolio/presentation/game/logo_overlay_component.dart';
import 'package:portfolio/presentation/game/title_layer_component.dart';

/// The Flame scene.
///
/// Owns the lit logo layer and reports into [SceneBloc]; it never decides
/// what stage the scene is in. Components read the state through
/// [FlameBlocProvider] and the game only forwards input and progress, so the
/// bloc stays the single authority over the sequence.
class MyGame extends FlameGame
    with
        ScrollDetector,
        TapCallbacks,
        PointerMoveCallbacks,
        MouseMovementDetector,
        HoverCallbacks {
  MyGame({
    required this.bloc,
    required this.palette,
    required this.audio,
  });

  final SceneBloc bloc;
  final ScenePalette palette;

  Queuer get queuer => bloc;

  late final LogoMarkComponent _mark;
  late final LogoShadowComponent _shadow;
  late final LogoOverlayComponent _overlay;
  late final TitleLayerComponent _title;
  late final BackdropComponent _backdrop;
  late final ScrollCueComponent _scrollCue;
  late final BoldTextComponent _boldText;

  /// Owns where the user is within the bold-text stage.
  ///
  /// Not in the bloc: this changes every frame while scrolling, and a bloc
  /// emitting sixty states a second to carry a double is the wrong tool. The
  /// bloc tracks which stage the scene is in; this tracks position within it.
  final ScrollDriver _scroll = ScrollDriver();

  /// True once the stage is running, so scroll and the arrow mean the bold
  /// text rather than the title.
  bool _boldTextActive = false;

  /// Everything that follows the pointer reads this rather than the raw
  /// position, so the scene glides after the cursor instead of snapping.
  final CursorTracker _cursor = CursorTracker();

  /// Passed in rather than pulled from [palette].
  ///
  /// The palette is an immutable snapshot of theme *values*; audio is a
  /// mutable service with its own lifecycle and state. Carrying it in there
  /// let two palettes compare equal while the backend they shared had
  /// different mute state, and hid a real dependency behind a value object.
  final AppAudio audio;

  /// One-shot *per visit to the logo screen*: the handover to the title
  /// happens once both halves of the logo layer have finished leaving.
  ///
  /// Armed again whenever that screen comes back — which it does on the
  /// contact screen, since that borrows the same composition and leaves it
  /// the same way.
  bool _exitReported = false;

  @override
  Color backgroundColor() => palette.background;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final logoProgram = await ui.FragmentProgram.fromAsset(
      'assets/shaders/logo.frag',
    );
    final raysProgram = await ui.FragmentProgram.fromAsset(
      'assets/shaders/god_rays.frag',
    );
    final metallicProgram = await ui.FragmentProgram.fromAsset(
      'assets/shaders/metallic_text.frag',
    );
    final backdropProgram = await ui.FragmentProgram.fromAsset(
      'assets/shaders/background_run_v2.frag',
    );
    final boldTextProgram = await ui.FragmentProgram.fromAsset(
      'assets/shaders/bold_text_entrance.frag',
    );
    _report(0.5);

    final artwork = await Flame.images.load('logo.png');
    _report(0.8);

    final markSize = markSizeFor(size);
    final centre = size / 2;
    _cursor.reset(centre);

    // Above the god-ray floor, not below it. Both shaders write opaque
    // full-screen colour, so they cannot be layered — the backdrop's fade is
    // a crossfade that replaces the lit floor as the title takes over.
    _backdrop = BackdropComponent(
      shader: backdropProgram.fragmentShader(),
      priority: SceneLayers.backdrop,
    )..size = size;

    _shadow =
        LogoShadowComponent(
            shader: raysProgram.fragmentShader(),
            artwork: artwork,
            priority: SceneLayers.shadow,
          )
          ..size = size
          ..markPosition = centre
          ..markSize = markSize
          ..lightPosition = centre
          ..cursorPosition = centre;

    _mark =
        LogoMarkComponent(
            shader: logoProgram.fragmentShader(),
            artwork: artwork,
            palette: palette,
            size: markSize,
            position: centre,
            priority: SceneLayers.mark,
          )
          ..homePosition = centre.clone()
          ..homeSize = markSize.clone();

    _overlay = LogoOverlayComponent(palette: palette, queuer: queuer)
      ..priority = SceneLayers.affordance;

    _title = TitleLayerComponent(
      palette: palette,
      program: metallicProgram,
      queuer: queuer,
      onPrimaryBegin: () => audio.play(AudioCue.titleLoaded),
      onSecondaryBegin: () => audio.play(AudioCue.slideIn),
    )..priority = SceneLayers.title;

    _boldText = BoldTextComponent(
      shader: boldTextProgram.fragmentShader(),
      text: palette.boldText,
      style: palette.boldTextStyle,
      priority: SceneLayers.boldText,
    );

    _scrollCue = ScrollCueComponent(
      onAdvance: requestAdvance,
      color: palette.scrollCue,
      shadow: palette.scrollCueShadow,
      priority: SceneLayers.scrollCue,
    );

    // The provider is what lets the components follow the scene's state
    // without the game shuttling it to them by hand.
    await add(
      FlameBlocProvider<SceneBloc, SceneState>.value(
        value: bloc,
        children: <Component>[
          _shadow,
          _backdrop,
          _mark,
          _overlay,
          _title,
          _boldText,
          _scrollCue,
        ],
      ),
    );

    // Cues are bound to the state machine rather than sprinkled through the
    // components, so what the scene sounds like can be read in one place.
    //
    // Every cue lands after the user's first tap, which matters on the web:
    // browsers refuse to play until the page has been interacted with, so
    // anything scheduled earlier would be silently dropped.
    await add(
      FlameBlocListener<SceneBloc, SceneState>(
        bloc: bloc,
        onNewState: _playCueFor,
      ),
    );

    unawaited(audio.preload());
    _report(1);
  }

  /// Cues that mark a *state change*.
  ///
  /// The title's own cues are not here: its animation starts well after the
  /// stage is entered, so they are fired by the layer at the moment the
  /// motion actually begins.
  /// Puts the bold-text stage back to its beginning.
  ///
  /// Returning from the corridor lands on the title with the stage spent, and
  /// three separate things wrong with it. The scroll sits at its end and
  /// `_boldTextHandedOver` makes [onScroll] discard every gesture, so the
  /// visitor can scroll all they like and never reach the gallery again. And
  /// the stage's *appearance* is wrong too: the title's offset and fade and
  /// the cue's fade are only ever written by [_driveBoldTextStage], which
  /// stops running the moment the stage is inactive — so they keep the values
  /// they held when the stage ended, with the title parked off the top of the
  /// screen at zero opacity and the arrow invisible beneath it.
  ///
  /// Resetting the counters alone therefore fixes the scrolling and leaves a
  /// blank screen. The mapping is re-run once from a rewound scroll instead,
  /// so every one of those values is restored by the same code that set them
  /// rather than by a second copy of the same arithmetic.
  void _rewindBoldTextStage() {
    _boldTextActive = false;
    _boldTextHandedOver = false;
    _tingPlayed = false;
    _scroll.reset();

    _driveBoldTextStage();
    // The mapping scrubs the swell as a side effect; at offset zero that is
    // the sound's first frame, which is not what a visitor arriving back at
    // the title should hear.
    audio.stopScrub(AudioCue.boldTextSwell);
  }

  /// Maps the scroll onto everything the stage moves.
  ///
  /// One offset drives all of it, so the text, the departing title and the
  /// cue can never disagree about how far through the user is.
  void _driveBoldTextStage() {
    final offset = _scroll.offset;

    _boldText.progress = _scroll.progress;

    // The title leaves upward as the text arrives, and has faded before it
    // reaches the top — a title still legible at the edge of the screen reads
    // as a layout fault rather than a departure.
    final exit = (offset / BoldTextConfig.titleParallaxExit).clamp(0.0, 1.0);
    final fade = 1 - (offset / BoldTextConfig.titleFadeEnd).clamp(0.0, 1.0);
    _title
      ..stageOffset = Vector2(0, BoldTextConfig.titleExitY * exit)
      ..stageFade = fade;

    // The arrow stays: the rest of the sequence is reached by clicking it
    // again, so it has to outlive the gesture it invited.
    _scrollCue.stageFade = BoldTextConfig.cueVisibility(_scroll.progress);

    // The swell is bound to position rather than triggered, so scrolling back
    // walks back out of the sound. Volume follows speed, so a slow scroll is
    // quiet and a fast one swells.
    audio.scrub(
      AudioCue.boldTextSwell,
      _scroll.progress,
      volume: (0.2 + _scroll.velocity.abs() / 900).clamp(0.0, 1.0),
    );

    // The stage hands over once the scroll is spent, not when the sequence
    // finishes drawing — the tail past the sequence is what confirms the user
    // meant to leave rather than pausing on the flash.
    if (_scroll.isComplete && !_boldTextHandedOver) {
      _boldTextHandedOver = true;
      audio.stopScrub(AudioCue.boldTextSwell);
      queuer.queue(event: const SceneEvent.boldTextCompleted());
    }

    if (!_tingPlayed && _scroll.progress >= 0.42) {
      _tingPlayed = true;
      audio.play(AudioCue.ting);
    } else if (_scroll.progress < 0.35) {
      _tingPlayed = false;
    }
  }

  bool _tingPlayed = false;
  bool _boldTextHandedOver = false;

  void _playCueFor(SceneState state) {
    // The handover to the title is a one-shot *per visit to the logo
    // screen*, and the contact screen is a second visit — it borrows that
    // composition and leaves it the same way. Left spent, the exit plays in
    // full and reports nothing, so the scene stops on `logoOverlayRemoving`
    // and the title never arrives. Keyed off the same rule the layers read,
    // so a further stage joining that composition cannot miss it.
    if (state.showsMark) _exitReported = false;

    state.maybeWhen(
      logoOverlayRemoving: () => audio.play(AudioCue.enter),
      title: () {
        audio.play(AudioCue.bouncyArrow);

        _rewindBoldTextStage();
      },
      // Nothing of the corridor's approach may be left standing under the
      // contact screen.
      contact: _rewindBoldTextStage,
      active: (_, _) {
        if (_boldTextActive) return;
        _boldTextActive = true;
        _scroll.reset();
      },
      orElse: () {},
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!isLoaded) return;

    final centre = size / 2;
    final markSize = markSizeFor(size);

    _backdrop.size = size;
    _shadow.size = size;
    _mark
      ..homePosition = centre.clone()
      ..homeSize = markSize.clone();

    // Only reposition the mark when it is actually at home — mid-retreat it
    // is between the centre and its corner, and snapping it back would undo
    // the animation on a resize.
    if (!_mark.hasSettled) {
      _mark
        ..size = markSize
        ..position = centre;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLoaded) return;

    _cursor.update(dt);

    if (_boldTextActive) {
      _scroll.update(dt);
      _driveBoldTextStage();
    }

    // The shadow needs to follow the mark, not just sit where it started —
    // otherwise the light keeps occluding against a shape that has moved.
    _shadow
      ..markPosition = _mark.position
      ..markSize = _mark.size
      ..lightPosition = _cursor.position
      ..cursorPosition = _cursor.position;

    // Once the backdrop is fully up, the lit floor beneath it is invisible;
    // skip its full-screen pass rather than rendering into a covered buffer.
    _shadow.isOccluded = _backdrop.isOpaque;

    _title
      ..lightPosition = _cursor.position
      ..primaryParallax = _cursor.parallax(size, CursorConfig.titleParallax)
      ..secondaryParallax = _cursor.parallax(
        size,
        CursorConfig.secondaryTitleParallax,
      );

    _reportExitWhenBothDone();
  }

  /// Hands over to the title once the mark has parked *and* the affordance
  /// has un-typed.
  ///
  /// These are independent timelines. Letting whichever lands first advance
  /// the scene is what puts the title on screen over leftover glyphs.
  void _reportExitWhenBothDone() {
    if (_exitReported) return;
    if (!_mark.hasSettled || !_overlay.hasCleared) return;

    _exitReported = true;
    queuer.queue(event: const SceneEvent.logoExitCompleted());
  }

  @override
  void onScroll(PointerScrollInfo info) {
    super.onScroll(info);
    // Scrolling and clicking the arrow are the same request; the bloc decides
    // whether it means anything yet.
    final delta = info.scrollDelta.global.y;

    // Once the stage has handed over, its scroll is spent. Continuing to
    // accept input here keeps driving a sequence the visitor has already left
    // and competes with the gallery for the same gesture.
    if (_boldTextHandedOver) return;

    if (_boldTextActive) {
      _scroll.scrollBy(delta);
      return;
    }

    // Before the stage, a downward scroll is just another way of asking to
    // move on — the same request the arrow makes.
    if (delta <= 0) return;
    _scrollCue.requestAdvance();
  }

  /// Called by the arrow. Before the stage it asks the bloc to move on; once
  /// the stage is running it steps to the next pause instead.
  void requestAdvance() {
    if (_boldTextActive) {
      _scroll.advanceToNextPause();
      return;
    }
    queuer.queue(event: const SceneEvent.advanceRequested());
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    // The bloc decides whether a tap means anything yet.
    queuer.queue(event: const SceneEvent.tapped());
  }

  @override
  void onMouseMove(PointerHoverInfo info) {
    super.onMouseMove(info);
    _trackCursor(info.eventPosition.widget);
  }

  @override
  void onPointerMove(PointerMoveEvent event) {
    super.onPointerMove(event);
    _trackCursor(event.localPosition);
  }

  /// Records where the pointer is. Nothing reads it directly — the tracker
  /// smooths it on the frame clock, so a fast flick does not whip the light
  /// across the scene.
  void _trackCursor(Vector2 position) {
    if (!isLoaded) return;

    _cursor.moveTo(position, size);

    // The overlay reasons in offsets from the centre of the screen rather
    // than absolute coordinates, so it behaves the same at any viewport size.
    _overlay.cursor = position - size / 2;
  }

  void _report(double value) => queuer.queue(
    event: SceneEvent.loadingProgressed(phase: LoadingPhase.game, value: value),
  );
}
