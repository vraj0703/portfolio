import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/material.dart';
import 'package:portfolio/domain/config/logo_config.dart';
import 'package:portfolio/domain/interfaces/queuer.dart';
import 'package:portfolio/domain/style/scene_palette.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/game/bouncy_line.dart';

/// The "tap to enter" affordance beneath the mark.
///
/// Two spring-driven lines flank the label and trail the cursor, so the
/// screen answers the pointer before the user has clicked anything — the
/// signal that the scene is live rather than a splash image.
///
/// The layer owns its own entrance timeline rather than being driven by the
/// curtain's progress. That keeps the two independent: retuning the reveal
/// cannot desynchronise the affordance, and the bloc is told when the
/// entrance is *actually* finished instead of guessing at a duration.
class LogoOverlayComponent extends PositionComponent
    with FlameBlocListenable<SceneBloc, SceneState> {
  LogoOverlayComponent({required this.palette, required this.queuer});

  final ScenePalette palette;
  final Queuer queuer;

  /// Nothing, once the menu is standing where the label does.
  ///
  /// The contact screen keeps this component for its two lines and replaces
  /// what they flank. Blanking the label rather than hiding the component is
  /// what keeps the lines' spring, their entrance and their pointer-tracking
  /// as one piece of behaviour instead of two.
  String get label => _isContact ? '' : palette.tapToEnter;

  bool _isContact = false;

  final BouncyLine _left = BouncyLine();
  final BouncyLine _right = BouncyLine();

  final Paint _linePaint = Paint()..style = PaintingStyle.fill;
  final Path _leftPath = Path();
  final Path _rightPath = Path();

  late final TextComponent _text;

  /// Entrance and exit run on separate clocks; only one is advancing at a
  /// time. Both are normalised `0..1`.
  double _entrance = 0;
  double _exit = 0;
  bool _entranceReported = false;
  bool _isLeaving = false;

  /// Whether the logo screen is the one on show.
  ///
  /// The entrance used to advance from the moment this mounted, which is
  /// while the loading screen still covers the scene. Two things followed
  /// from that, and both were bugs: the label typed itself out behind the
  /// curtain and was already finished by the time anyone could see it, and
  /// on any load slower than the entrance the completion report — which
  /// fires exactly once — was raised while the scene was still loading.
  bool _isOnShow = false;

  /// Cursor position in this component's own space, so the lines lean the
  /// right way regardless of where the layer sits on screen.
  Vector2 cursor = Vector2.zero();

  Vector2 _viewport = Vector2.zero();

  /// True once the label has fully un-typed on the way out. The scene gates
  /// the next stage on this so the title never enters over leftover glyphs.
  bool get hasCleared => _isLeaving && _exit >= 1;

  @visibleForTesting
  double get entrance => _entrance;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    anchor = Anchor.center;

    _text = TextComponent(
      text: '',
      textRenderer: TextPaint(style: palette.enterStyle),
      anchor: Anchor.center,
    );
    add(_text);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _viewport = size;
    position = Vector2(size.x / 2, size.y - LogoConfig.overlayBottomMargin);
  }

  @override
  void onInitialState(SceneState state) {
    super.onInitialState(state);
    // The state in force when this mounted never arrives as a *change*, so
    // without this the entrance would wait for a transition into a state the
    // scene is already in.
    _isOnShow = state is Logo;
  }

  @override
  void onNewState(SceneState state) {
    super.onNewState(state);

    state.maybeWhen(
      contact: () {
        _isContact = true;
        _replay();
      },
      logo: (_) {
        _isContact = false;
        _isOnShow = true;
        // Re-entering the logo (e.g. returning from a later section) replays
        // the entrance rather than snapping to the finished pose.
        if (_isLeaving) _replay();
      },
      logoOverlayRemoving: () => _isLeaving = true,
      // Loading is the one stage where nothing has happened yet: the layer
      // is waiting behind the curtain and must not be told it is leaving.
      loading: (_) {},
      orElse: () {
        // Anywhere past the logo screen the affordance has no business on
        // the stage. Going from the contact screen into the gallery never
        // runs the exit that normally clears it, so without this the two
        // lines stay lit and reappear over the title on the way back.
        _isLeaving = true;
      },
    );
  }

  /// Winds the affordance back so its entrance plays again.
  void _replay() {
    _isOnShow = true;
    _isLeaving = false;
    _entrance = 0;
    _exit = 0;
    _entranceReported = false;
    _left.reset();
    _right.reset();
  }

  /// Half the clear space the lines leave between them.
  double get _gap =>
      _isContact ? LogoConfig.contactGap(_viewport.x) : LogoConfig.lineGap;

  @override
  void update(double dt) {
    super.update(dt);

    if (_isLeaving) {
      _advanceExit(dt);
    } else {
      _advanceEntrance(dt);
    }

    _left.update(dt);
    _right.update(dt);
  }

  void _advanceEntrance(double dt) {
    if (!_isOnShow) return;

    final duration = LogoConfig.entranceDuration.inMilliseconds / 1000;
    if (_entrance < 1) {
      _entrance = (_entrance + dt / duration).clamp(0.0, 1.0);
    }

    if (_entrance >= 1 && !_entranceReported) {
      _entranceReported = true;
      queuer.queue(event: const SceneEvent.logoEntranceCompleted());
    }

    _text.text = label.substring(0, (label.length * _typed).floor());
    _text.textRenderer = TextPaint(
      style: palette.enterStyle.copyWith(
        color: palette.overlayText.withValues(alpha: _layerOpacity),
      ),
    );

    // Lines trail the pointer, mapped from its distance off centre.
    if (_viewport.x > 0) {
      final reach = (cursor.x.abs() / (_viewport.x / 2)).clamp(0.0, 1.0);
      final travel = reach * LogoConfig.lineTravel;
      _right.target = travel;
      _left.target = -travel;
    }
  }

  void _advanceExit(double dt) {
    if (_exit < 1) {
      _exit = (_exit + LogoConfig.textExitSpeed * dt).clamp(0.0, 1.0);
    }

    // Un-types from the end, so the instruction retracts rather than fading.
    final remaining = ((1 - _exit) * label.length).floor();
    _text.text = label.substring(0, remaining);
    _text.textRenderer = TextPaint(
      style: palette.enterStyle.copyWith(
        color: palette.overlayText.withValues(alpha: (1 - _exit).clamp(0, 1)),
      ),
    );

    // Both lines fling outward as the layer leaves.
    _right.target = LogoConfig.lineTravel;
    _left.target = -LogoConfig.lineTravel;
  }

  /// Fraction of the label that has typed on.
  double get _typed => LogoConfig.typedAt(_entrance);

  /// Overall opacity of the layer.
  double get _layerOpacity =>
      _isLeaving ? (1 - _exit).clamp(0.0, 1.0) : _entrance.clamp(0.0, 1.0);

  /// Opacity of the lines, which arrive after the layer has begun fading in.
  double get _lineOpacity {
    if (_isLeaving) return (1 - _exit).clamp(0.0, 1.0);
    if (_entrance <= LogoConfig.linesStart) return 0;
    return ((_entrance - LogoConfig.linesStart) / (1 - LogoConfig.linesStart))
        .clamp(0.0, 1.0);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final opacity = _lineOpacity;
    if (opacity <= 0.001) return;

    _drawLine(canvas, line: _right, path: _rightPath, gap: _gap);
    _drawLine(canvas, line: _left, path: _leftPath, gap: -_gap);
  }

  /// Draws one tapered line: thick at the inner end, near-nothing at the
  /// outer, filled with a glassy gradient so it reads as bevelled rather than
  /// as a plain rule.
  void _drawLine(
    Canvas canvas, {
    required BouncyLine line,
    required Path path,
    required double gap,
  }) {
    final length = LogoConfig.lineLength * line.scale;
    final startX = line.position + gap;
    final endX = startX + (gap > 0 ? length : -length);

    const halfStart = LogoConfig.lineStartThickness / 2;
    const halfEnd = LogoConfig.lineEndThickness / 2;

    path
      ..reset()
      ..moveTo(startX, -halfStart)
      ..lineTo(endX, -halfEnd)
      ..lineTo(endX, halfEnd)
      ..lineTo(startX, halfStart)
      ..close();

    _linePaint
      ..shader = ui.Gradient.linear(
        Offset(startX, -LogoConfig.lineStartThickness),
        Offset(startX, LogoConfig.lineStartThickness),
        palette.lineGradient,
        palette.lineStops,
      )
      ..color = Color.fromRGBO(255, 255, 255, _lineOpacity);

    canvas.drawPath(path, _linePaint);
  }
}
