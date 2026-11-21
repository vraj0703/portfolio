import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/material.dart';
import 'package:portfolio/domain/config/title_config.dart';
import 'package:portfolio/domain/interfaces/queuer.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/domain/config/title_contrast.dart';
import 'package:portfolio/presentation/game/metallic_text_component.dart';
import 'package:portfolio/presentation/game/rehearsal_pass.dart';
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
    with FlameBlocListenable<SceneBloc, SceneState>
    implements Rehearsable {
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

  /// The name's width at rest, fitted to the screen (logical px): what the
  /// parallax is a share of. Zero until it has laid out.
  double get nameRestWidth {
    if (!isLoaded || !_primary.isMounted) return 0;
    return _primary.size.x *
        TitleConfig.primaryFit(
          naturalWidth: _primary.size.x,
          viewportWidth: _viewportWidth,
        );
  }

  /// The name as it is drawn now, for the dimming behind it
  /// (PORTFOLIO-22): its fade (the entrance's and the exit's, the one the
  /// glyphs are drawn with), its centre on screen and its width at its
  /// current scale. Read, not timed: the dimming follows the name's own
  /// animation, so the two arrive and leave as one thing.
  NameBand get nameBand {
    if (!isLoaded || !_primary.isMounted) return NameBand.absent;
    final centre = _primary.absolutePosition;
    return NameBand(
      presence: _primary.fade,
      centreXPx: centre.x,
      centreYPx: centre.y,
      halfWidthPx: _primary.size.x * _primary.scale.x.abs() / 2,
    );
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    anchor = Anchor.center;

    // How the name holds its own against the backdrop (PORTFOLIO-22): (B)
    // and (D) darken its metal, give it a soft dark shadow and more weight.
    final way = TitleContrastConfig.current;
    final warm = way == TitleContrast.warmBand;
    final darker =
        way == TitleContrast.darkerName ||
        way == TitleContrast.dimAndDarker ||
        warm;
    final light = way == TitleContrast.dimAndDarker || warm;
    // (E) takes the weight but not the shadow: a blurred shadow needs GL
    // programs the loading rehearsal does not compile (the census showed 6
    // linked after the tap, against 2), and E reaches 3:1 without it.
    final nameStyle = warm
        ? palette.titlePrimaryStyle.copyWith(fontWeight: FontWeight.w700)
        : darker
        ? palette.titlePrimaryStyle.copyWith(
            fontWeight: FontWeight.w700,
            shadows: <Shadow>[
              Shadow(
                color: Color.fromRGBO(
                  0,
                  0,
                  0,
                  light
                      ? TitleContrastConfig.shadowAlphaLight
                      : TitleContrastConfig.shadowAlpha,
                ),
                blurRadius: TitleContrastConfig.shadowBlur,
              ),
            ],
          )
        : palette.titlePrimaryStyle;
    // (E) a slightly brighter metal: against a dimmed band, darker letters
    // lose contrast (why D fell short).
    final nameBase = warm
        ? const Color(TitleContrastConfig.warmNameBase)
        : darker
        ? Color(
            light
                ? TitleContrastConfig.darkerBaseLight
                : TitleContrastConfig.darkerBase,
          )
        : palette.titleBase;

    _primary =
        MetallicTextComponent(
            text: palette.primaryTitle,
            style: nameStyle,
            program: program,
            baseColor: nameBase,
            anchor: Anchor.center,
            priority: 8,
          )
          ..scale = Vector2.all(TitleConfig.primaryStartScale)
          ..hidden = TitleContrastConfig.hideName;

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
    // (C) lifts the name off the bright band; the others leave it centred.
    position = Vector2(
      size.x / 2,
      size.y / 2 -
          TitleContrastConfig.riseFor(TitleContrastConfig.current) * size.y,
    );
    _viewportWidth = size.x;
  }

  /// How wide the screen is, for fitting the name to it.
  double _viewportWidth = 0;

  @override
  void onInitialState(SceneState state) {
    super.onInitialState(state);
    _rehearse(state);

    // The stage the game *mounted into* never arrives as a change, so without
    // this the title waits for a transition into a state the scene is already
    // in — and waits forever. Leaving the gallery rebuilds the game straight
    // into the title stage, which is exactly that case: the timeline never
    // started, nothing was drawn, and all the visitor saw was the bare mark,
    // which reads as having been dropped back at the logo.
    if (hasBegunBy(state)) _elapsed ??= 0;
  }

  /// Whether the title's entrance has started by the time [state] is reached.
  ///
  /// Matched through the union rather than with `is Title`, because Flutter
  /// exports a `Title` widget of its own and importing both into one library
  /// is ambiguous.
  static bool hasBegunBy(SceneState state) => state.maybeMap(
    titleLoading: (_) => true,
    title: (_) => true,
    active: (_) => true,
    orElse: () => false,
  );

  @override
  void onNewState(SceneState state) {
    super.onNewState(state);
    _rehearse(state);

    state.maybeMap(
      titleLoading: (_) => _elapsed ??= 0,
      // Returning to the logo rewinds the stage so it plays again rather than
      // snapping straight to the finished pose.
      logo: (_) => _rewind(),
      // The contact screen clears the stage the same way. Home then arrives
      // as `titleLoading`, so the entrance plays again from the top rather
      // than the titles snapping back on.
      contact: (_) => _rewind(),
      orElse: () {
        // Reached the title without passing through its loading stage —
        // which is what walking back out of the gallery does, and what the
        // contact screen's rewind leaves behind when the visitor goes round
        // by the gallery. Started rather than snapped: they are looking at
        // the screen when it happens.
        if (hasBegunBy(state)) _elapsed ??= 0;
      },
    );
  }

  /// Ready once the name and every glyph of the line beneath are mounted:
  /// they are added in [onLoad] without waiting, so they arrive after this.
  @override
  bool get readyToRehearse =>
      isMounted && _primary.isMounted && _secondary.glyphsMounted;

  /// The scene's rule ([SceneState.rehearsesTitle]), handed to the glyphs,
  /// which have no state of their own. Drawing only: the timeline, the cues
  /// and the report are untouched.
  void _rehearse(SceneState state) {
    _primary.rehearsing = state.rehearsesTitle;
    _secondary.rehearsing = state.rehearsesTitle;

    // The name waits at scale zero for its entrance, and a draw of no size
    // is rejected before the GPU. Rehearsed at its rest size instead; the
    // entrance sets the scale from its timeline on its first frame
    // (`_drivePrimary`), and the name is not drawn until then.
    if (state.rehearsesTitle) {
      _primary.scale = Vector2.all(
        TitleConfig.primaryFit(
          naturalWidth: _primary.size.x,
          viewportWidth: _viewportWidth,
        ),
      );
    }
  }

  /// Across the name's middle, where its letters are, and the centre of each
  /// glyph of the line beneath.
  @override
  List<Vector2> get rehearsalPoints {
    final box = _primary.toAbsoluteRect();
    return <Vector2>[
      for (var i = 1; i < 12; i++)
        Vector2(box.left + box.width * i / 12, box.center.dy),
      ..._secondary.glyphCentres,
    ];
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
    final scale =
        TitleConfig.primaryStartScale +
        (1 - TitleConfig.primaryStartScale) *
            TitleTimeline.primaryScale(elapsed);

    // Fitted to the screen as well as grown: on a phone the name at its
    // designed size is wider than the screen, so it would grow into a crop.
    final fit = TitleConfig.primaryFit(
      naturalWidth: _primary.size.x,
      viewportWidth: _viewportWidth,
    );

    _primary
      ..fade = TitleTimeline.primaryFade(elapsed) * stageFade
      ..scale = Vector2.all(scale * fit)
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
