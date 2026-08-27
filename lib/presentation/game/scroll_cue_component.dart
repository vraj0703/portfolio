import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/material.dart';
import 'package:portfolio/domain/config/scroll_cue_config.dart';
import 'package:portfolio/domain/interfaces/queuer.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';

/// The bouncing arrow that invites the user onward from the title.
///
/// Drawn rather than loaded: the original is a six-point chevron in a 24x24
/// box, which is less code as a [Path] than as an SVG asset plus a loader,
/// and scales cleanly to any size.
///
/// Clicking it and scrolling mean the same thing, so both raise the same
/// event — the arrow does not own the decision, it just offers one of two
/// ways to ask.
class ScrollCueComponent extends PositionComponent
    with FlameBlocListenable<SceneBloc, SceneState>, TapCallbacks {
  ScrollCueComponent({required this.queuer, required this.color, super.priority});

  final Queuer queuer;
  final Color color;

  /// The chevron, in the artwork's own 24x24 space.
  static const List<Offset> _chevron = <Offset>[
    Offset(12, 15.632),
    Offset(20.968, 10.884),
    Offset(20.032, 9.116),
    Offset(12, 13.368),
    Offset(3.968, 9.116),
    Offset(3.032, 10.884),
  ];

  final Path _path = Path();
  final Paint _paint = Paint()..style = PaintingStyle.fill;
  final Paint _shadowPaint = Paint()
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(
      BlurStyle.normal,
      ScrollCueConfig.shadowBlur,
    );

  double _elapsed = 0;
  double _opacity = 0;
  bool _isVisible = false;

  @visibleForTesting
  double get opacity => _opacity;

  @override
  void onNewState(SceneState state) {
    super.onNewState(state);

    state.maybeWhen(
      // Only offered once the title has finished arriving; before that there
      // is nothing to move on from.
      title: () => _isVisible = true,
      active: (_, isArrowVisible) => _isVisible = isArrowVisible,
      orElse: () {
        _isVisible = false;
        _opacity = 0;
      },
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    final height = ScrollCueConfig.size * (ScrollCueConfig.artboard / 24);
    this.size = Vector2(ScrollCueConfig.size, height);

    // Anchored on its own centre so the bounce and the hit box stay
    // symmetrical about the resting position.
    anchor = Anchor.center;
    position = Vector2(
      size.x / 2,
      size.y - ScrollCueConfig.bottomMargin,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    final fade = ScrollCueConfig.fadeIn.inMilliseconds / 1000;
    final target = _isVisible ? 1.0 : 0.0;
    final step = dt / fade;
    _opacity = (_opacity + (target > _opacity ? step : -step)).clamp(0.0, 1.0);
  }

  /// Vertical offset of the bounce, `0` at rest.
  ///
  /// A raised cosine rather than a sawtooth, so it eases at both ends instead
  /// of snapping at the extremes.
  double get _bounce {
    final period = ScrollCueConfig.bouncePeriod.inMilliseconds / 1000;
    final phase = (_elapsed % period) / period;
    return ScrollCueConfig.bounceDistance *
        (1 - math.cos(phase * 2 * math.pi)) /
        2;
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    // The chevron is thin; matching the hit box to it exactly is awkward with
    // a mouse and unusable with a thumb.
    final centre = size / 2;
    return (point.x - centre.x).abs() <= ScrollCueConfig.touchPadX &&
        (point.y - centre.y - _bounce).abs() <= ScrollCueConfig.touchPadY;
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    if (_opacity <= 0.5) return; // not really offered yet
    queuer.queue(event: const SceneEvent.advanceRequested());
  }

  @override
  void render(Canvas canvas) {
    if (_opacity <= 0.001) return;

    final scale = ScrollCueConfig.size / ScrollCueConfig.artboard;
    _path.reset();
    for (var i = 0; i < _chevron.length; i++) {
      final p = _chevron[i] * scale;
      final y = p.dy + _bounce;
      if (i == 0) {
        _path.moveTo(p.dx, y);
      } else {
        _path.lineTo(p.dx, y);
      }
    }
    _path.close();

    // Shadow first: without it the arrow disappears against the lighter
    // passages of the animated backdrop.
    _shadowPaint.color = const Color(0xFF000000).withValues(
      alpha: 0.55 * _opacity,
    );
    canvas.save();
    canvas.translate(0, ScrollCueConfig.shadowOffsetY);
    canvas.drawPath(_path, _shadowPaint);
    canvas.restore();

    _paint.color = color.withValues(alpha: _opacity);
    canvas.drawPath(_path, _paint);
  }

  /// Exposed so the game can forward a scroll to the same place a tap goes.
  void requestAdvance() {
    if (_opacity <= 0.5) return;
    queuer.queue(event: const SceneEvent.advanceRequested());
  }

  @visibleForTesting
  ui.Path get debugPath => _path;
}
