import 'dart:async';
import 'dart:ui' as ui;
import 'dart:ui' show Color;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:portfolio/domain/audio/app_audio.dart';
import 'package:portfolio/domain/config/cursor_config.dart';
import 'package:portfolio/domain/config/scene_layers.dart';
import 'package:portfolio/domain/interfaces/queuer.dart';
import 'package:portfolio/domain/models/loading_phase.dart';
import 'package:portfolio/domain/style/scene_palette.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/game/backdrop_component.dart';
import 'package:portfolio/presentation/game/cursor_tracker.dart';
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

  /// One-shot: the handover to the title happens once, when both halves of
  /// the logo layer have finished leaving.
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

    _scrollCue = ScrollCueComponent(
      queuer: queuer,
      color: palette.scrollCue,
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
  void _playCueFor(SceneState state) {
    state.maybeWhen(
      logoOverlayRemoving: () => audio.play(AudioCue.enter),
      title: () => audio.play(AudioCue.bouncyArrow),
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
    if (info.scrollDelta.global.y <= 0) return;
    _scrollCue.requestAdvance();
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
