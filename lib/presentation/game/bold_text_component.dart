import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// The bold-text stage, drawn entirely by its shader.
///
/// Everything the user sees here — the text arriving with a back-overshoot,
/// the shine sweeping across it, the starfield streaming outward, the final
/// flash as it all clears — is a function of one uniform, [progress]. That is
/// what lets a wheel, a trackpad and a click on the arrow drive the same
/// sequence without three animations to keep in step.
///
/// The text itself is rasterised once into a texture and handed to the
/// shader, rather than laid out per frame: the shader needs to sample it at
/// arbitrary offsets to blur, scale and reflect it, which it cannot do with
/// glyphs it has never seen.
class BoldTextComponent extends PositionComponent {
  BoldTextComponent({
    required this.shader,
    required this.text,
    required this.style,
    super.priority,
  });

  final ui.FragmentShader shader;
  final String text;
  final TextStyle style;

  /// Longest line the text is allowed to occupy before wrapping.
  static const double maxTextWidth = 800;

  /// Breathing room baked into the texture, so the shader can blur and
  /// displace the glyphs without sampling past their own edges.
  static const double texturePadding = 60;

  ui.Image? _texture;
  final Paint _paint = Paint();
  bool _shaderAttached = false;

  /// The sequence's position, `0`..`1`.
  double progress = 0;

  /// Fades the whole stage, independent of [progress].
  double opacity = 1;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _texture = await _rasterise();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  Future<ui.Image> _rasterise() async {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: maxTextWidth);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    painter.paint(canvas, const Offset(texturePadding, texturePadding));

    final picture = recorder.endRecording();
    try {
      return await picture.toImage(
        (painter.width + texturePadding * 2).ceil(),
        (painter.height + texturePadding * 2).ceil(),
      );
    } finally {
      picture.dispose();
      painter.dispose();
    }
  }

  @override
  void render(Canvas canvas) {
    final texture = _texture;
    if (texture == null) return;

    // The shader draws nothing at either extreme, so skipping the draw
    // outright saves a full-screen pass for most of the scene's life.
    if (progress <= 0.001 || progress >= 0.999) return;
    if (opacity <= 0.001) return;

    shader
      ..setFloat(0, size.x)
      ..setFloat(1, size.y)
      ..setFloat(2, progress)
      ..setFloat(3, texture.width.toDouble())
      ..setFloat(4, texture.height.toDouble())
      ..setFloat(5, opacity)
      ..setImageSampler(0, texture);

    // Attached only once the sampler is bound: assigning a shader to a Paint
    // validates that every sampler it declares has a value.
    if (!_shaderAttached) {
      _paint.shader = shader;
      _shaderAttached = true;
    }

    canvas.drawRect(size.toRect(), _paint);
  }

  @override
  void onRemove() {
    _texture?.dispose();
    _texture = null;
    super.onRemove();
  }
}
