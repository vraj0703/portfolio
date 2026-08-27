import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/material.dart';
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
  BackdropComponent({required this.shader, super.priority});

  final ui.FragmentShader shader;

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

  @override
  void onNewState(SceneState state) {
    super.onNewState(state);

    state.maybeWhen(
      // Starts with the mark's retreat, not with the title, so the two
      // overlap rather than queue.
      logoOverlayRemoving: () => _isRising = true,
      logo: (_) {
        _isRising = false;
        _opacity = 0;
      },
      orElse: () {},
    );
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

  @override
  void render(Canvas canvas) {
    if (_opacity <= 0.001) return;
    if (size.x <= 0 || size.y <= 0) return;

    shader
      ..setFloat(0, size.x)
      ..setFloat(1, size.y)
      ..setFloat(2, _elapsed);

    _paint.shader = shader;
    final rect = size.toRect();

    if (_opacity >= 0.999) {
      canvas.drawRect(rect, _paint);
      return;
    }

    // saveLayer rather than a Paint alpha: the shader writes its own colour,
    // so the fade has to be applied to the composited result.
    canvas.saveLayer(rect, Paint()..color = Color.fromRGBO(0, 0, 0, _opacity));
    canvas.drawRect(rect, _paint);
    canvas.restore();
  }
}
