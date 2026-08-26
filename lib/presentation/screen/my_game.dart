import 'dart:ui' as ui;
import 'dart:ui' show Color;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:portfolio/domain/interfaces/queuer.dart';
import 'package:portfolio/domain/models/loading_phase.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/game/logo_layer.dart';
import 'package:portfolio/presentation/game/logo_overlay_component.dart';
import 'package:portfolio/presentation/game/scene_palette.dart';

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
  MyGame({required this.bloc, required this.palette});

  final SceneBloc bloc;
  final ScenePalette palette;

  Queuer get queuer => bloc;

  late final LogoMarkComponent _mark;
  late final LogoShadowComponent _shadow;
  late final LogoOverlayComponent _overlay;

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
    _report(0.5);

    final artwork = await Flame.images.load('logo.png');
    _report(0.8);

    final markSize = markSizeFor(size);
    final centre = size / 2;

    _shadow = LogoShadowComponent(
      shader: raysProgram.fragmentShader(),
      artwork: artwork,
    )
      ..size = size
      ..markPosition = centre
      ..markSize = markSize
      ..lightPosition = centre
      ..cursorPosition = centre;

    _mark = LogoMarkComponent(
      shader: logoProgram.fragmentShader(),
      artwork: artwork,
      palette: palette,
      size: markSize,
      position: centre,
    );

    _overlay = LogoOverlayComponent(palette: palette, queuer: queuer);

    // The provider is what lets the components follow the scene's state
    // without the game shuttling it to them by hand.
    await add(
      FlameBlocProvider<SceneBloc, SceneState>.value(
        value: bloc,
        children: <Component>[_shadow, _mark, _overlay],
      ),
    );

    _report(1);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!isLoaded) return;

    final centre = size / 2;
    final markSize = markSizeFor(size);

    _shadow
      ..size = size
      ..markPosition = centre
      ..markSize = markSize;
    _mark
      ..size = markSize
      ..position = centre;
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

  /// Points the light at the cursor and leans the affordance's lines with it.
  void _trackCursor(Vector2 position) {
    if (!isLoaded) return;

    _shadow
      ..lightPosition = position
      ..cursorPosition = position;

    // The overlay reasons in offsets from the centre of the screen rather
    // than absolute coordinates, so it behaves the same at any viewport size.
    _overlay.cursor = position - size / 2;
  }

  void _report(double value) => queuer.queue(
    event: SceneEvent.loadingProgressed(phase: LoadingPhase.game, value: value),
  );
}
