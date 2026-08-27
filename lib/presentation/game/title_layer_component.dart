import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/material.dart';
import 'package:portfolio/domain/config/title_config.dart';
import 'package:portfolio/domain/interfaces/queuer.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/game/metallic_text_component.dart';
import 'package:portfolio/presentation/game/secondary_title_component.dart';
import 'package:portfolio/domain/style/scene_palette.dart';
import 'package:portfolio/domain/config/title_timeline.dart';

/// The hero title stage: the name, then the line beneath it.
///
/// Runs its own choreography once the scene enters `titleLoading` and reports
/// back when it is done, the same contract the logo layer uses. The bloc
/// never times the animation; it is told when the animation finished.
///
/// The sequence is deliberately unhurried — a beat, the name resolving out of
/// nothing over three seconds, a drift upward like heat, then the line. Each
/// pause is doing work; compressing them makes the stage read as a single
/// event rather than an arrival.
class TitleLayerComponent extends PositionComponent
    with FlameBlocListenable<SceneBloc, SceneState> {
  TitleLayerComponent({
    required this.palette,
    required this.program,
    required this.queuer,
    this.onPrimaryBegin,
    this.onSecondaryBegin,
  });

  final ScenePalette palette;
  final ui.FragmentProgram program;
  final Queuer queuer;

  /// Called when the name *starts resolving*, not when the stage is entered.
  ///
  /// The two are two seconds apart — the stage opens on a deliberate pause —
  /// so a cue hung off the state change plays to an empty screen and is
  /// already fading by the time the name appears.
  final VoidCallback? onPrimaryBegin;

  /// Called when the line beneath is released, so the scene can sound it.
  final VoidCallback? onSecondaryBegin;

  late final MetallicTextComponent _primary;
  late final SecondaryTitleComponent _secondary;

  /// Seconds since the stage began. Null until it has.
  double? _elapsed;
  bool _reported = false;
  bool _primarySounded = false;

  /// Pointer-driven offsets. The two differ on purpose — moving the line
  /// beneath the name slightly less is what reads as depth rather than as one
  /// flat plate sliding around.
  Vector2 primaryParallax = Vector2.zero();
  Vector2 secondaryParallax = Vector2.zero();

  /// Where the light sits, in logical screen coordinates. Fed from the
  /// smoothed cursor so the sheen travels across the letterforms as the
  /// pointer moves, rather than sitting as a static gradient.
  Vector2 lightPosition = Vector2.zero();

  /// Displacement applied by whatever stage follows the title.
  ///
  /// Kept separate from the parallax so the two compose instead of fighting:
  /// the pointer keeps nudging the title while the scroll carries it away.
  Vector2 stageOffset = Vector2.zero();

  /// Fade applied by the following stage, multiplied into the entry's own.
  double stageFade = 1;

  @visibleForTesting
  bool get isRunning => _elapsed != null;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    anchor = Anchor.center;

    _primary = MetallicTextComponent(
      text: palette.primaryTitle,
      style: palette.titlePrimaryStyle,
      program: program,
      baseColor: palette.titleBase,
      anchor: Anchor.center,
      priority: 8,
    )..scale = Vector2.all(TitleConfig.primaryStartScale);

    // Same metal as the name, so the two read as one object catching one
    // light rather than a shaded title with a plain caption under it. Built
    // glyph by glyph because the entry animates each character separately.
    _secondary = SecondaryTitleComponent(
      text: palette.secondaryTitle,
      style: palette.titleSecondaryStyle,
      program: program,
      baseColor: palette.titleBase,
      position: Vector2(0, TitleConfig.secondaryOffsetY),
      priority: 8,
      onComplete: _reportEntranceComplete,
      onBegin: onSecondaryBegin,
    );

    addAll(<Component>[_primary, _secondary]);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = size / 2;
  }

  @override
  void onNewState(SceneState state) {
    super.onNewState(state);

    state.maybeWhen(
      titleLoading: () => _elapsed ??= 0,
      // Returning to the logo rewinds the stage so it plays again rather than
      // snapping straight to the finished pose.
      logo: (_) => _rewind(),
      orElse: () {},
    );
  }

  void _rewind() {
    _elapsed = null;
    _reported = false;
    _primarySounded = false;
    _primary
      ..fade = 0
      ..scale = Vector2.all(TitleConfig.primaryStartScale)
      ..position = Vector2.zero();
    _secondary
      ..rewind()
      ..position = Vector2(0, TitleConfig.secondaryOffsetY);
  }

  void _reportEntranceComplete() {
    if (_reported) return;
    _reported = true;
    queuer.queue(event: const SceneEvent.titleEntranceCompleted());
  }

  @override
  void update(double dt) {
    super.update(dt);

    final elapsed = _elapsed;
    if (elapsed == null) return;
    _elapsed = elapsed + dt;

    // The shader works in screen space, so both pieces get the same light —
    // they are lit by one source, not each by their own.
    _primary.lightPosition = lightPosition;
    _secondary.lightPosition = lightPosition;

    if (!_primarySounded && elapsed >= TitleTimeline.primaryStart) {
      _primarySounded = true;
      onPrimaryBegin?.call();
    }

    _drivePrimary(elapsed);
    _driveSecondary(elapsed);

    // The line beneath runs its own per-glyph choreography and reports for
    // itself, so the stage ends when it says so rather than on a clock the
    // two would have to be kept in step with.
    if (elapsed >= TitleTimeline.secondaryStart) _secondary.begin();
  }

  /* -- Timeline -------------------------------------------------------- */

  void _drivePrimary(double elapsed) {
    final scale = TitleConfig.primaryStartScale +
        (1 - TitleConfig.primaryStartScale) *
            TitleTimeline.primaryScale(elapsed);

    _primary
      ..fade = TitleTimeline.primaryFade(elapsed) * stageFade
      ..scale = Vector2.all(scale)
      // Heat drift: a slow upward creep beginning before the fade finishes,
      // so the name never sits perfectly still.
      ..position =
          primaryParallax +
          stageOffset +
          Vector2(0, TitleConfig.driftY * TitleTimeline.drift(elapsed));
  }


  void _driveSecondary(double elapsed) {
    // Only the parallax is driven from here; the entry belongs to the line.
    _secondary
      ..position =
          secondaryParallax +
          stageOffset +
          Vector2(0, TitleConfig.secondaryOffsetY)
      ..stageFade = stageFade;
  }
}
