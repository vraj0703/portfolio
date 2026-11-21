import 'dart:async';
import 'dart:ui' as ui;
import 'dart:ui' show Color;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:portfolio/data/analytics/analytics_setup.dart' show Browser;
import 'package:portfolio/domain/audio/app_audio.dart';
import 'package:portfolio/domain/config/backdrop_detail.dart';
import 'package:portfolio/domain/config/bold_text_config.dart';
import 'package:portfolio/domain/config/cursor_config.dart';
import 'package:portfolio/domain/config/pointer_config.dart';
import 'package:portfolio/domain/pointer/pointer_status.dart';
import 'package:portfolio/domain/config/scene_layers.dart';
import 'package:portfolio/domain/interfaces/queuer.dart';
import 'package:portfolio/domain/models/loading_phase.dart';
import 'package:portfolio/domain/style/scene_palette.dart';
import 'package:portfolio/domain/utils/cursor_tracker.dart';
import 'package:portfolio/domain/utils/scroll_driver.dart';
import 'package:portfolio/domain/utils/strokes.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/game/backdrop_component.dart';
import 'package:portfolio/presentation/game/bold_text_component.dart';
import 'package:portfolio/presentation/game/contact_dim_component.dart';
import 'package:portfolio/presentation/game/logo_layer.dart';
import 'package:portfolio/presentation/game/logo_overlay_component.dart';
import 'package:portfolio/presentation/game/pointer_adapter.dart';
import 'package:portfolio/presentation/game/rehearsal_pass.dart';
import 'package:portfolio/presentation/game/scroll_cue_component.dart';
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
        // Touch. `ScrollDetector` is a wheel, and a phone has none — without
        // this the bold-text stage cannot be advanced at all on one, because
        // scrolling *is* the stage. `PointerMoveCallbacks` looks like it
        // would cover this and does not: Flame builds its `PointerMoveEvent`
        // from a `PointerHoverEvent`, so it is mouse movement, and a finger
        // never hovers.
        DragCallbacks,
        TapCallbacks,
        PointerMoveCallbacks,
        MouseMovementDetector,
        HoverCallbacks {
  MyGame({
    required this.bloc,
    required this.palette,
    required this.audio,
    PointerStatus? pointerStatus,
  }) : pointer = PointerAdapter(
         phone: Browser.isPhone(),
         status: pointerStatus,
       );

  /// Where the scene's one pointer comes from: the mouse, a finger, the
  /// tilt or the idle drift (PORTFOLIO-27). It feeds [_cursor]; nothing else
  /// reads input for the light or the parallax.
  final PointerAdapter pointer;

  final SceneBloc bloc;
  final ScenePalette palette;

  Queuer get queuer => bloc;

  late final LogoMarkComponent _mark;
  late final LogoShadowComponent _shadow;
  late final LogoOverlayComponent _overlay;
  late final TitleLayerComponent _title;
  late final BackdropComponent _backdrop;
  late final ScrollCueComponent _scrollCue;
  late final ContactDimComponent _contactDim;
  late final ContactDimComponent _contactArrival;
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
      // Phones march fewer, longer steps: the backdrop was the whole title
      // frame there (8.4 fps at DPR 2.0 on the ROG, 34.7 with this).
      detail: BackdropDetail.forDevice(phone: Browser.isPhone()),
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
          ..homeSize = markSize.clone()
          ..viewport = size.clone();

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

    _contactDim = ContactDimComponent(
      colour: palette.contactDim,
      wash: ContactWash.dim,
      priority: SceneLayers.contactDim,
    );

    // The dark the corridor went out through, lifting off the ground the
    // contact screen stands on — and off nothing else. Under the mark, so
    // the mark that flew in from the corridor is not blinked out at the
    // moment it arrives, and under the menu, which has an entrance of its
    // own.
    _contactArrival = ContactDimComponent(
      colour: palette.sceneVeil,
      wash: ContactWash.arrival,
      priority: SceneLayers.contactArrival,
    );

    _scrollCue = ScrollCueComponent(
      onAdvance: requestAdvance,
      onPressed: () => audio.play(AudioCue.click),
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
          _contactArrival,
          _mark,
          _contactDim,
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
        onNewState: (state) {
          _playCueFor(state);
          pointer.scene(state);
        },
      ),
    );
    pointer.scene(bloc.state);

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
    _strokePending = false;
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
    //
    // Nothing at all until the visitor has moved. Bound to position means
    // position zero is the sound's first frame, and scrubbing to it the
    // moment the stage opens plays that frame — a swell that arrives before
    // the gesture it is meant to accompany. It went unnoticed for as long as
    // it did because the file path was mis-escaped and the scrub failed
    // silently; fixing that made an old bug audible.
    if (_scroll.progress <= 0) {
      audio.stopScrub(AudioCue.boldTextSwell);
    } else {
      audio.scrub(
        AudioCue.boldTextSwell,
        _scroll.progress,
        volume: (0.2 + _scroll.velocity.abs() / 900).clamp(0.0, 1.0),
      );
    }

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

    state.maybeMap(
      logoOverlayRemoving: (_) => audio.play(AudioCue.enter),
      title: (_) {
        audio.play(AudioCue.bouncyArrow);

        final queued = _strokePending;
        _rewindBoldTextStage();
        _strokePending = queued;
        _sendQueuedStroke();
      },
      // Arriving in the corridor. Hung off the state rather than off the
      // two things that reach it — the bold text running out, and the
      // gallery mark on the contact menu — so both doors sound the same.
      gallery: (_) => audio.play(AudioCue.galleryEntry),
      // Nothing of the corridor's approach may be left standing under the
      // contact screen.
      contact: (_) => _rewindBoldTextStage(),
      active: (_) {
        if (_boldTextActive) return;
        _boldTextActive = true;
        _scroll.reset();
        if (_strokePending) _scroll.advanceToNextPause();
        _strokePending = false;
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
      ..homeSize = markSize.clone()
      ..viewport = size.clone();

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

    // The adapter says where the pointer is (a finger, the mouse, the tilt
    // or the drift); the tracker smooths it, once, as it always has.
    final target = pointer.update(dt, size);
    if (target != null) _trackCursor(target);
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

    // A portrait phone's own, smaller parallax (PointerConfig).
    final portrait = size.y > size.x;
    _title
      ..lightPosition = _cursor.position
      ..primaryParallax = _cursor.parallax(
        size,
        portrait
            ? PointerConfig.titleParallaxPortrait
            : CursorConfig.titleParallax,
      )
      ..secondaryParallax = _cursor.parallax(
        size,
        portrait
            ? PointerConfig.secondaryTitleParallaxPortrait
            : CursorConfig.secondaryTitleParallax,
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

  /// How far a finger moves the intro, against how far it travels, where it
  /// scrolls rather than strokes (a mouse drag, or the strokes' flag off).
  ///
  /// A wheel notch reports about a hundred units; a finger reports the pixels
  /// it crossed. Left at one-to-one the stage still works, but reading a
  /// paragraph takes a handful of full-screen swipes, which is not what the
  /// same gesture costs anywhere else on a phone.
  static const double dragScrollGain = 2;

  /// The wheel scrolls, continuously, as it always has. Strokes are for
  /// touch only: as strokes, a wheel spun or a trackpad's flick (one long
  /// burst of events) played its first stroke and swallowed the rest, and
  /// the title hung on the bold text until the visitor stopped and scrolled
  /// again (Vishal, 2026-11-18; reproduced on desktop Chrome).
  @override
  void onScroll(PointerScrollInfo info) {
    super.onScroll(info);
    _advanceBy(info.scrollDelta.global.y);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _dragTravelled = 0;
    _dragStroked = false;
    _dragFinger = !_isMouse(event.deviceKind);
    if (_dragFinger) pointer.fingerDown(event.canvasPosition);
    // A finger or a pen strokes, when the scene's rule says so; a mouse
    // drag scrolls, as it always has. Asked as "not a mouse": some touch
    // reaches Flutter web with an unknown kind (seen with adb and CDP touch),
    // and a finger must not fall back to the mouse's drag.
    _dragStrokes =
        event.deviceKind != PointerDeviceKind.mouse &&
        event.deviceKind != PointerDeviceKind.trackpad &&
        bloc.state.swipesByStroke;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (_dragFinger) pointer.fingerMoved(event.canvasEndPosition);
    if (!_dragStrokes) {
      // A finger moving *up* is a wheel turning down: both mean "onward".
      _advanceBy(-event.localDelta.y * dragScrollGain);
      return;
    }
    // One swipe is one stroke, decided once it has gone far enough to say
    // which way; the rest of the swipe is the same gesture.
    if (_dragStroked) return;
    _dragTravelled += event.localDelta.y;
    final direction = Strokes.dragDirection(_dragTravelled);
    if (direction == 0) return;
    _dragStroked = true;
    _stroke(direction);
  }

  /// Moves the intro on by [delta]: the wheel's continuous scroll (and a
  /// drag's, where it does not stroke). Master's, unchanged.
  void _advanceBy(double delta) {
    // Once the stage has handed over, its scroll is spent.
    if (_boldTextHandedOver) return;
    if (_boldTextActive) {
      _scroll.scrollBy(delta);
      return;
    }
    // Before the stage, a downward scroll is just another way of asking to
    // move on: the same request the arrow makes.
    if (delta <= 0) return;
    _scrollCue.requestAdvance();
  }

  /// Whether the drag under way is a finger's (asked once, at its start).
  bool _dragFinger = false;

  /// The finger's stroke state.
  double _dragTravelled = 0;
  bool _dragStroked = false;
  bool _dragStrokes = false;

  /// A stroke onward from the title, made before the stage was running:
  /// the stage plays it as soon as it opens, so the one stroke carries the
  /// visitor from the title to the bold text.
  bool _strokePending = false;

  /// One stroke, onward ([direction] `1`) or back (`-1`): a timed move to
  /// the next or the previous pause.
  void _stroke(int direction) {
    // Once the stage has handed over, its scroll is spent. Continuing to
    // accept input here keeps driving a sequence the visitor has already left
    // and competes with the gallery for the same gesture.
    if (_boldTextHandedOver || direction == 0) return;

    if (_boldTextActive) {
      // A stroke while one is playing is the same request again.
      if (_scroll.isMoving) return;
      if (direction > 0) {
        _scroll.advanceToNextPause();
      } else {
        _scroll.retreatToPreviousPause();
      }
      return;
    }

    // Before the stage, a stroke onward asks for it, and the stage carries
    // it on to the bold text once it opens. Only while the title is
    // arriving or settled: a swipe on the logo screen is not a request to
    // skip the title.
    if (direction < 0) return;
    final state = bloc.state;
    if (state is! TitleLoading && state is! Title) return;
    _strokePending = true;
    // The bloc takes it in the settled title. Made while the title is still
    // arriving, it is queued and sent the moment the title settles
    // ([_sendQueuedStroke]): no waiting on the arrow's fade, no time limit.
    queuer.queue(event: const SceneEvent.advanceRequested());
  }

  /// A stroke made while the title was arriving, sent as it settles.
  void _sendQueuedStroke() {
    if (!_strokePending) return;
    queuer.queue(event: const SceneEvent.advanceRequested());
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
    // A finger is the pointer while it is down. Asked as "not a mouse", as
    // the drag is: some touch reaches Flutter web with an unknown kind.
    if (_isMouse(event.deviceKind)) {
      pointer.mouseMoved(event.canvasPosition);
    } else {
      pointer.fingerDown(event.canvasPosition);
    }
    // The bloc decides whether a tap means anything yet.
    queuer.queue(event: const SceneEvent.tapped());
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    pointer.fingerUp();
    // The logo's tap, inside its own handler: the one moment iOS lets the
    // page ask for the phone's motion. Asked once, there.
    if (bloc.state is Logo) pointer.logoTapped();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    super.onTapCancel(event);
    pointer.fingerUp();
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    pointer.fingerUp();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    pointer.fingerUp();
  }

  static bool _isMouse(PointerDeviceKind? kind) =>
      kind == PointerDeviceKind.mouse || kind == PointerDeviceKind.trackpad;

  @override
  void onMouseMove(PointerHoverInfo info) {
    super.onMouseMove(info);
    pointer.mouseMoved(info.eventPosition.widget);
  }

  @override
  void onPointerMove(PointerMoveEvent event) {
    super.onPointerMove(event);
    pointer.mouseMoved(event.localPosition);
  }

  /// Hands the tracker where the pointer is this frame, as the adapter chose
  /// it. Nothing reads it directly — the tracker smooths it on the frame
  /// clock, so a fast flick does not whip the light across the scene.
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

  /* -- Rehearsal ------------------------------------------------------- */

  /// Frames the title stage's real draws are rehearsed while loading
  /// ([SceneState.rehearsesTitle]), through `RehearsalPixel`.
  ///
  /// One compiles every program; the second is where a compile's tail lands,
  /// still behind the loading screen rather than on the first visible frame.
  static const int rehearsalFrames = 2;

  /// How far [LoadingPhase.rehearsal] has got after [frames] rehearsed.
  static double rehearsalProgress(int frames) =>
      (frames / rehearsalFrames).clamp(0.0, 1.0);

  int _rehearsed = 0;

  /// The components whose draws are rehearsed. A frame counts only once all
  /// of them are mounted, because a frame they were not in compiled nothing.
  List<PositionComponent> get _rehearsalCast => <PositionComponent>[
    _backdrop,
    _title,
    _scrollCue,
    _boldText,
  ];

  /// The game `RehearsalPixel` draws from, while it is mounted.
  ///
  /// The pixel is a widget over the loading screen and the game sits under
  /// it; this is the one line between them.
  static final ValueNotifier<MyGame?> stage = ValueNotifier<MyGame?>(null);

  @override
  void onMount() {
    super.onMount();
    stage.value = this;
  }

  @override
  void onRemove() {
    if (stage.value == this) stage.value = null;
    pointer.dispose();
    super.onRemove();
  }

  static bool _readyToRehearse(Component actor) => switch (actor) {
    final Rehearsable cast => cast.readyToRehearse,
    _ => actor.isMounted,
  };

  /// Draws the rehearsal cast into [canvas], which the caller has clipped,
  /// and counts the frame into [LoadingPhase.rehearsal].
  ///
  /// The draws have to be the screen's own and the last in their pixel.
  /// Under the opaque loading screen they never reached the GPU, and a
  /// picture rasterised offscreen compiles in another WebGL context than the
  /// screen's (GL census on the ROG, 2026-11-17: three contexts, screen,
  /// toImageSync and flutter_scene). Each component decides what to draw
  /// from the scene's rule, as it does on screen.
  void rehearseInto(ui.Canvas canvas) {
    // [rehearsalFrames] and no more: every frame of it is the title stage
    // drawn in full while the loading it hides behind is still running.
    if (_rehearsed >= rehearsalFrames) return;
    if (!bloc.state.rehearsesTitle) return;
    if (!isLoaded || !_rehearsalCast.every(_readyToRehearse)) return;

    RehearsalPass.active = true;
    try {
      for (final actor in _rehearsalCast) {
        // Moved so a pixel it inks lands on the clip: a draw whose bounds miss
        // the clip is rejected before the GPU. A translation leaves the
        // program as it is.
        final points = switch (actor) {
          final Rehearsable cast => cast.rehearsalPoints,
          _ => <Vector2>[actor.absoluteCenter],
        };
        for (final point in points) {
          canvas
            ..save()
            ..translate(-point.x, -point.y);
          actor.renderTree(canvas);
          canvas.restore();
        }
      }
    } finally {
      RehearsalPass.active = false;
    }

    _rehearsed++;
    queuer.queue(
      event: SceneEvent.loadingProgressed(
        phase: LoadingPhase.rehearsal,
        value: rehearsalProgress(_rehearsed),
      ),
    );
  }
}
