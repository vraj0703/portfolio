import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/material.dart';
import 'package:portfolio/presentation/game/rehearsal_pass.dart';
import 'package:portfolio/domain/config/backdrop_detail.dart';
import 'package:portfolio/domain/config/title_contrast.dart';
import 'package:portfolio/domain/config/title_config.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';

/// The animated backdrop that comes up behind the hero title.
///
/// Hidden through the logo stage — the mark is the subject there, and a moving
/// background would compete with it. It begins fading in the moment the mark
/// starts retreating and is still arriving as the name resolves, so there is
/// never a frame where the background visibly switches on.
class BackdropComponent extends PositionComponent
    with FlameBlocListenable<SceneBloc, SceneState> {
  BackdropComponent({
    required this.shader,
    this.detail = BackdropDetail.full,
    super.priority,
  });

  final ui.FragmentShader shader;

  /// How much work the shader does per pixel, chosen for the device by the
  /// game (`BackdropDetail.forDevice`), not by this component.
  final BackdropDetail detail;

  final Paint _paint = Paint();

  double _elapsed = 0;
  double _opacity = 0;
  bool _isRising = false;

  @visibleForTesting
  double get opacity => _opacity;

  /// True once this pass covers the screen completely. The layer beneath can
  /// stop rendering at that point — it writes opaque colour too, so none of
  /// it is reaching the screen any more.
  bool get isOpaque => _opacity >= 1;

  /// Whether the backdrop is already up by the time [state] is reached.
  static bool hasRisenBy(SceneState state) => !state.showsMark;

  @override
  void onInitialState(SceneState state) {
    super.onInitialState(state);
    _rehearsing = state.rehearsesTitle;

    // Anything past the logo is a stage this backdrop is already behind, so
    // it starts fully risen rather than waiting for a rise it missed.
    if (hasRisenBy(state)) {
      _isRising = true;
      _opacity = 1;
    }
  }

  @override
  void onNewState(SceneState state) {
    super.onNewState(state);
    _rehearsing = state.rehearsesTitle;

    state.maybeMap(
      // Starts with the mark's retreat, not with the title, so the two
      // overlap rather than queue.
      logoOverlayRemoving: (_) => _isRising = true,
      logo: (_) => _fall(),
      contact: (_) => _fall(),
      orElse: () {
        // Up already by this stage, and never seen to rise. Same reason as
        // the mark's: the ways out of the contact screen do not pass through
        // the stage that raises it, and a title with no ground under it is
        // the mark and the words floating on nothing.
        if (hasRisenBy(state) && !_isRising) {
          _isRising = true;
          _opacity = 1;
        }
      },
    );
  }

  void _fall() {
    _isRising = false;
    _opacity = 0;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // The shader animates continuously; the clock runs whether or not it is
    // visible so it does not start from a cold pose when it fades up.
    _elapsed += dt;

    if (_isRising && _opacity < 1) {
      final duration = TitleConfig.backdropFadeIn.inMilliseconds / 1000;
      _opacity = (_opacity + dt / duration).clamp(0.0, 1.0);
    }
  }

  /// Whether this frame rehearses the backdrop under the curtain
  /// ([SceneState.rehearsesTitle]); the scene's rule, read here.
  bool _rehearsing = false;

  /// The opacities [render] draws at this frame, one pass each.
  ///
  /// Rehearsing, both of the real draw's two paths, opaque and faded: they
  /// are two different GPU programs (seen as two compiles at the tap on a
  /// phone, 2026-11-17), and the rise after the tap uses both.
  @visibleForTesting
  static List<double> passesFor({
    required bool rehearsing,
    required double opacity,
  }) {
    if (rehearsing) return const <double>[1, 0.5];
    if (opacity <= 0.001) return const <double>[];
    return <double>[opacity];
  }

  @override
  void render(Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;
    final passes = passesFor(
      rehearsing: _rehearsing && RehearsalPass.active,
      opacity: _opacity,
    );
    if (passes.isEmpty) return;

    shader
      ..setFloat(0, size.x)
      ..setFloat(1, size.y)
      ..setFloat(2, TitleContrastConfig.pinnedTime ?? _elapsed)
      ..setFloat(3, detail.steps.toDouble())
      ..setFloat(4, detail.octaves.toDouble())
      ..setFloat(5, detail.stepScale)
      // The dimming behind the name (TitleContrastConfig). Centred where the
      // name sits: the screen's middle, or higher for (C).
      ..setFloat(6, TitleContrastConfig.dimFor(TitleContrastConfig.current))
      ..setFloat(7, TitleContrastConfig.riseFor(TitleContrastConfig.current))
      ..setFloat(8, TitleContrastConfig.dimHalfWidth)
      ..setFloat(9, TitleContrastConfig.dimHalfHeight);

    _paint.shader = shader;
    final rect = size.toRect();

    for (final opacity in passes) {
      _draw(canvas, rect, opacity);
    }
  }

  void _draw(Canvas canvas, Rect rect, double opacity) {
    if (opacity >= 0.999) {
      canvas.drawRect(rect, _paint);
      return;
    }

    // saveLayer rather than a Paint alpha: the shader writes its own colour,
    // so the fade has to be applied to the composited result.
    canvas.saveLayer(rect, Paint()..color = Color.fromRGBO(0, 0, 0, opacity));
    canvas.drawRect(rect, _paint);
    canvas.restore();
  }
}
