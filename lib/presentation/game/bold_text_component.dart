import 'dart:ui' as ui;

import 'package:portfolio/domain/config/bold_text_layout.dart';
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

  /// The wrap width and type scale the texture was set at, so a resize that
  /// changes neither does not set it again.
  (double, double)? _setAt;

  /// Counts rasterisations, so a slow one that finishes after a newer one
  /// started is dropped rather than drawn.
  int _generation = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final viewport = findGame()?.size ?? size;
    await _setFor(Size(viewport.x, viewport.y));
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    // Rotating a phone changes the width the text has: set it again.
    if (isLoaded) _setFor(Size(size.x, size.y));
  }

  /// Rasterises the text for a screen of [viewport] ([BoldTextLayout]).
  Future<void> _setFor(Size viewport) async {
    final key = (
      BoldTextLayout.wrapWidthFor(viewport),
      BoldTextLayout.scaleFor(viewport),
    );
    if (key == _setAt) return;
    _setAt = key;
    final generation = ++_generation;
    final image = await _rasterise(wrapWidth: key.$1, scale: key.$2);
    if (generation != _generation || isRemoved) {
      image.dispose();
      return;
    }
    final old = _texture;
    _texture = image;
    old?.dispose();
  }

  Future<ui.Image> _rasterise({
    required double wrapWidth,
    required double scale,
  }) async {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(
          fontSize: (style.fontSize ?? 14) * scale,
          letterSpacing: (style.letterSpacing ?? 0) * scale,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: wrapWidth);

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

  /// Whether the shader's program has been compiled yet, by [render]'s
  /// one invisible warm-up draw.
  bool _warmed = false;

  /// What [render] does this frame: compile the shader with an invisible
  /// draw, draw it for real, or nothing.
  ///
  /// The warm-up exists because skipping the draw at the extremes (below)
  /// meant the shader's first draw was the visitor's first scroll step, and
  /// that is when CanvasKit compiles it into a GPU program. A trace of the
  /// touch scroll on a phone profile (tool/web_profile.py, flame-scroll)
  /// showed it as one 420-460 ms frame, `getProgramParameter` under
  /// `Surface.flush`, 0.4 s after the first touch: the hang. Drawn once on the
  /// first frame instead, the compile happens behind the loading screen.
  @visibleForTesting
  static BoldTextDraw drawFor({
    required bool warmed,
    required double progress,
    required double opacity,
  }) {
    if (!warmed) return BoldTextDraw.warmUp;
    if (progress <= 0.001 || progress >= 0.999) return BoldTextDraw.none;
    if (opacity <= 0.001) return BoldTextDraw.none;
    return BoldTextDraw.full;
  }

  @override
  void render(Canvas canvas) {
    final texture = _texture;
    if (texture == null) return;

    switch (drawFor(warmed: _warmed, progress: progress, opacity: opacity)) {
      case BoldTextDraw.warmUp:
        // Progress 0 takes the shader's first branch and writes transparent
        // black, so the one-pixel draw compiles the whole program and paints
        // nothing.
        _bind(texture, progress: 0, opacity: 0);
        canvas.drawRect(const Rect.fromLTWH(0, 0, 1, 1), _paint);
        _warmed = true;
        return;
      case BoldTextDraw.none:
        // The shader draws nothing at either extreme, so skipping the draw
        // outright saves a full-screen pass for most of the scene's life.
        return;
      case BoldTextDraw.full:
        break;
    }

    _bind(texture, progress: progress, opacity: opacity);
    canvas.drawRect(size.toRect(), _paint);
  }

  void _bind(
    ui.Image texture, {
    required double progress,
    required double opacity,
  }) {
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
  }

  @override
  void onRemove() {
    _texture?.dispose();
    _texture = null;
    super.onRemove();
  }
}

/// What [BoldTextComponent.render] does in a frame.
enum BoldTextDraw {
  /// The one invisible draw that compiles the shader, on the first frame.
  warmUp,

  /// Nothing: the shader would draw nothing anyway.
  none,

  /// The real draw.
  full,
}
