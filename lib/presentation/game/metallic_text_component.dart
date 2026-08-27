import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Text painted with the metallic shader, so the glyphs read as brushed metal
/// catching a moving light rather than as a flat fill.
///
/// Each instance builds its **own** [ui.FragmentShader] from the shared
/// program. This is not incidental: a canvas records draw commands and
/// executes them later, so two components sharing one shader would each
/// overwrite the other's uniforms before either draw reached the GPU. The
/// result is glyphs flickering and inheriting each other's opacity — a bug
/// that looks like a driver fault rather than aliasing.
class MetallicTextComponent extends TextComponent with HasGameReference {
  MetallicTextComponent({
    required super.text,
    required TextStyle style,
    required ui.FragmentProgram program,
    required this.baseColor,
    super.position,
    super.anchor,
    super.priority,
  }) : _shader = program.fragmentShader(),
       super(textRenderer: TextPaint(style: style)) {
    // The Paint holds the shader for the component's whole life; only the
    // shader's uniforms change per frame. Rebuilding the TextPaint each frame
    // would re-lay-out the glyphs for nothing. Assigned here rather than in
    // the initialiser list, which cannot reference `this`.
    textRenderer = TextPaint(
      style: style.copyWith(foreground: Paint()..shader = _shader),
    );
  }

  final Color baseColor;
  final ui.FragmentShader _shader;

  double _elapsed = 0;

  /// Fades the glyphs, `0`..`1`.
  ///
  /// Named `fade` rather than `opacity` deliberately: [TextComponent] already
  /// carries an `opacity`, and shadowing it would leave two properties that
  /// look interchangeable but are not — this one is handed to the shader, so
  /// the sheen dims with the glyphs instead of being composited over them.
  double fade = 0;

  /// Where the light sits, in **logical** screen coordinates.
  ///
  /// Fed from the smoothed cursor, which is what makes the sheen travel
  /// across the letterforms as the pointer moves. Converted to physical
  /// pixels at render time, because that is the space the shader works in.
  Vector2 lightPosition = Vector2.zero();

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
  }

  @override
  void render(Canvas canvas) {
    if (fade <= 0.001) return;
    if (size.x <= 0 || size.y <= 0) return;

    // The shader reads `FlutterFragCoord()`, which is in physical pixels, so
    // every position and extent handed to it has to be scaled the same way.
    // Passing logical values here is silently wrong: the glyphs still paint,
    // but the UVs map against the wrong frame and the metal shades as though
    // the text were somewhere else entirely.
    final dpr = game.canvasSize.x / game.size.x;
    final topLeft = absolutePositionOf(Vector2.zero()) * dpr;

    _shader
      ..setFloat(0, size.x * dpr)
      ..setFloat(1, size.y * dpr)
      ..setFloat(2, topLeft.x)
      ..setFloat(3, topLeft.y)
      ..setFloat(4, _elapsed)
      ..setFloat(5, baseColor.r)
      ..setFloat(6, baseColor.g)
      ..setFloat(7, baseColor.b)
      ..setFloat(8, fade.clamp(0.0, 1.0))
      ..setFloat(9, lightPosition.x * dpr)
      ..setFloat(10, lightPosition.y * dpr);

    super.render(canvas);
  }

  @override
  void onRemove() {
    _shader.dispose();
    super.onRemove();
  }
}
