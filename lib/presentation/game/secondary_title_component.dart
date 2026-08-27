import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:portfolio/domain/config/secondary_title_timeline.dart';

import 'metallic_text_component.dart';

/// The line beneath the hero title, animated glyph by glyph.
///
/// Each character is its own component so it can fade, rise, squash and
/// settle on its own offset clock. Laid out by measuring the glyphs rather
/// than by letting a single [TextComponent] handle spacing — the whole point
/// is that they move independently, which a single text run cannot do.
class SecondaryTitleComponent extends PositionComponent {
  SecondaryTitleComponent({
    required this.text,
    required this.style,
    required this.program,
    required this.baseColor,
    required this.onComplete,
    this.onBegin,
    super.position,
    super.priority,
  }) : super(anchor: Anchor.center);

  final String text;
  final TextStyle style;
  final ui.FragmentProgram program;
  final Color baseColor;

  /// Fired once, when every glyph has settled.
  final VoidCallback onComplete;

  /// Fired once, the moment the entry starts. The slide cue belongs to this
  /// animation rather than to a scene state — the line is released partway
  /// through `titleLoading`, so there is no state change to hang it on.
  final VoidCallback? onBegin;

  final List<MetallicTextComponent> _glyphs = <MetallicTextComponent>[];
  final List<double> _restX = <double>[];

  double? _elapsed;
  bool _reported = false;

  /// Where the light sits, in logical screen coordinates. Passed through to
  /// every glyph so the line is lit by one source rather than each character
  /// carrying its own.
  Vector2 lightPosition = Vector2.zero();

  @visibleForTesting
  int get glyphCount => _glyphs.length;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Measure each glyph so they can be positioned individually, then centre
    // the run on the component's origin.
    final painter = TextPainter(textDirection: TextDirection.ltr);
    final widths = <double>[];
    var total = 0.0;

    for (final char in text.characters) {
      painter
        ..text = TextSpan(text: char, style: style)
        ..layout();
      widths.add(painter.width);
      total += painter.width;
    }

    final spacing = style.letterSpacing ?? 0;
    final span = total + (widths.length - 1) * spacing;
    var cursor = -span / 2;

    final chars = text.characters.toList();
    for (var i = 0; i < chars.length; i++) {
      final glyph = MetallicTextComponent(
        text: chars[i],
        style: style,
        program: program,
        baseColor: baseColor,
        anchor: Anchor.center,
      )..fade = 0;

      final restX = cursor + widths[i] / 2;
      _restX.add(restX);
      glyph.position = Vector2(restX, SecondaryTitleTimeline.riseFrom);

      _glyphs.add(glyph);
      add(glyph);

      cursor += widths[i] + spacing;
    }
  }

  /// Starts the entry. Ignored if it is already running.
  void begin() {
    if (_elapsed != null) return;
    _elapsed = 0;
    onBegin?.call();
  }

  /// Returns the line to its pre-entry pose so it can play again.
  void rewind() {
    _elapsed = null;
    _reported = false;
    for (var i = 0; i < _glyphs.length; i++) {
      _glyphs[i]
        ..fade = 0
        ..scale = Vector2.all(1)
        ..position = Vector2(_restX[i], SecondaryTitleTimeline.riseFrom);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    final elapsed = _elapsed;
    if (elapsed == null) return;
    _elapsed = elapsed + dt;

    final slide = SecondaryTitleTimeline.slideOffset(elapsed);

    for (var i = 0; i < _glyphs.length; i++) {
      _glyphs[i]
        ..lightPosition = lightPosition
        ..fade = SecondaryTitleTimeline.opacityOf(elapsed, i)
        ..position = Vector2(
          _restX[i] + slide,
          SecondaryTitleTimeline.riseOf(elapsed, i),
        )
        ..scale = Vector2(
          SecondaryTitleTimeline.scaleXOf(elapsed, i),
          SecondaryTitleTimeline.scaleYOf(elapsed, i),
        );
    }

    if (!_reported &&
        SecondaryTitleTimeline.isComplete(elapsed, _glyphs.length)) {
      _reported = true;
      onComplete();
    }
  }
}
