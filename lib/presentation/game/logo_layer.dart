import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:portfolio/domain/config/logo_config.dart';
import 'package:portfolio/presentation/game/scene_palette.dart';

/// The mark, drawn through the logo shader.
///
/// The shader reads the artwork's alpha and hardens the edge, and the paint
/// tints the result. It is tinted with the scene's own background colour on
/// purpose: the mark is not meant to read as a coloured shape sitting on the
/// ground, but as the ground itself, cut out and lit. [LogoShadowComponent]
/// underneath is what makes that legible — without it this is invisible.
class LogoMarkComponent extends PositionComponent {
  LogoMarkComponent({
    required this.shader,
    required this.artwork,
    required this.palette,
    required super.size,
    required super.position,
  }) : super(anchor: Anchor.center) {
    _paint = Paint()
      ..colorFilter = ColorFilter.mode(palette.background, BlendMode.srcIn);
  }

  final ui.FragmentShader shader;
  final ui.Image artwork;
  final ScenePalette palette;

  late final Paint _paint;

  /// Set on the first render, once the shader's sampler has a value.
  ///
  /// Assigning a shader to a Paint validates that every sampler it declares
  /// is bound, so the shader cannot be attached in the constructor — the
  /// artwork has not been handed to it yet at that point.
  bool _shaderAttached = false;

  /// Fades with the layer's entrance and exit.
  double opacity = 1;

  @override
  void render(Canvas canvas) {
    if (opacity <= 0.001) return;

    shader
      ..setFloat(0, size.x)
      ..setFloat(1, size.y)
      ..setImageSampler(0, artwork);

    if (!_shaderAttached) {
      _paint.shader = shader;
      _shaderAttached = true;
    }

    final rect = Offset.zero & size.toSize();
    if (opacity >= 0.999) {
      canvas.drawRect(rect, _paint);
      return;
    }

    canvas.saveLayer(rect, Paint()..color = Color.fromRGBO(0, 0, 0, opacity));
    canvas.drawRect(rect, _paint);
    canvas.restore();
  }
}

/// Full-screen light pass that gives the mark its relief.
///
/// The god-ray shader marches from each pixel toward the light, sampling the
/// mark's alpha, so the mark occludes light and throws rays across the scene.
/// The light follows the cursor, which is what makes the whole layer feel
/// lit rather than painted.
class LogoShadowComponent extends PositionComponent {
  LogoShadowComponent({required this.shader, required this.artwork});

  final ui.FragmentShader shader;
  final ui.Image artwork;

  final Paint _paint = Paint();

  /// Where the light sits, in screen space.
  Vector2 lightPosition = Vector2.zero();

  /// Where the cursor sits, in screen space. The shader uses it to bias the
  /// ray direction, so the rays lean as the pointer moves.
  Vector2 cursorPosition = Vector2.zero();

  /// The mark's centre and extent, so the shader knows what is occluding.
  Vector2 markPosition = Vector2.zero();
  Vector2 markSize = Vector2.zero();

  double opacity = 1;

  @override
  void render(Canvas canvas) {
    if (opacity <= 0.001) return;
    if (size.x == 0 || size.y == 0) return;

    shader
      ..setFloat(0, size.x)
      ..setFloat(1, size.y)
      ..setFloat(2, lightPosition.x)
      ..setFloat(3, lightPosition.y)
      ..setFloat(4, markPosition.x)
      ..setFloat(5, markPosition.y)
      ..setFloat(6, markSize.x)
      ..setFloat(7, markSize.y)
      ..setFloat(8, cursorPosition.x)
      ..setFloat(9, cursorPosition.y)
      ..setImageSampler(0, artwork);

    _paint.shader = shader;

    final rect = Offset.zero & size.toSize();
    if (opacity >= 0.999) {
      canvas.drawRect(rect, _paint);
      return;
    }

    canvas.saveLayer(rect, Paint()..color = Color.fromRGBO(0, 0, 0, opacity));
    canvas.drawRect(rect, _paint);
    canvas.restore();
  }
}

/// Sizes the mark to the viewport, preserving the artwork's aspect.
///
/// Delegates to [LogoConfig.markWidthFor] so the mark is the same size here
/// as it is on the loading curtain — they show the same logo either side of
/// the reveal, and any difference reads as the logo changing size.
Vector2 markSizeFor(Vector2 viewport) {
  final width = LogoConfig.markWidthFor(
    viewportWidth: viewport.x,
    viewportHeight: viewport.y,
  );
  return Vector2(width, width * LogoConfig.markAspect);
}
