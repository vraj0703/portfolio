import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:portfolio/domain/config/pointer_config.dart';
import 'package:portfolio/domain/pointer/pointer_path.dart';

/// Chooses where the scene's one pointer comes from, and where it is
/// (PORTFOLIO-27). Pure: it is told what the input did and what time it is,
/// and answers; it reads no sensor and runs no clock.
///
/// The order: a finger while it is down; on desktop, a mouse that has moved
/// in the last [PointerConfig.mouseIdle] seconds; on a phone being tilted,
/// the tilt;
/// otherwise the idle drift. Reduced motion keeps the finger and the mouse
/// (the visitor moving them) and puts everything else at the centre.
///
/// It does no smoothing: the `CursorTracker` it feeds does that, once. The
/// one easing here is the hand-over to a virtual source, which is part of
/// the path, so the pointer travels to the new source instead of jumping.
class PointerChooser {
  PointerChooser({required this.phone, this.reducedMotion = false});

  /// A phone: tilt and touch, no mouse.
  final bool phone;

  /// The visitor asked the system for less motion: no drift, no tilt.
  bool reducedMotion;

  Vector2? _finger;
  Vector2? _mouse;
  double _mouseAt = double.negativeInfinity;

  double? _beta, _gamma, _baseBeta, _baseGamma;
  double _screenAngle = 0;

  double _sceneAt = 0;
  double _driftFrom = 0;
  PointerSource? _source;
  Vector2? _handFrom;
  double _handAt = 0;
  Vector2 _last = Vector2.zero();

  /// The source chosen by the last [target].
  PointerSource get source => _source ?? PointerSource.still;

  /// A scene appeared at [now]: the tilt is measured from how the phone is
  /// held now (the latest reading, or the first to come), and a desktop's
  /// idle wait starts again.
  void sceneAppeared(double now) {
    _sceneAt = now;
    _baseBeta = _beta;
    _baseGamma = _gamma;
  }

  void mouseMoved(Vector2 at, double now) {
    _mouse = at.clone();
    _mouseAt = now;
  }

  void fingerDown(Vector2 at) => _finger = at.clone();
  void fingerMoved(Vector2 at) => _finger = at.clone();
  void fingerUp() => _finger = null;

  /// A tilt reading. With no angle held yet, this is it: the pointer starts
  /// at the centre and moves from there.
  void tilted(double beta, double gamma, double now, {double screenAngle = 0}) {
    _baseBeta ??= beta;
    _baseGamma ??= gamma;
    _beta = beta;
    _gamma = gamma;
    _screenAngle = screenAngle;
    final restBeta = _restBeta, restGamma = _restGamma;
    if (restBeta == null ||
        restGamma == null ||
        _apart(beta, restBeta) > PointerConfig.tiltMoved ||
        _apart(gamma, restGamma) > PointerConfig.tiltMoved) {
      // Moving again after a rest: measured from the angle it rested at, so
      // it starts from the centre rather than wherever the old angle puts it.
      if (restBeta != null && !_tiltLive(now)) {
        _baseBeta = restBeta;
        _baseGamma = restGamma;
      }
      _restBeta = beta;
      _restGamma = gamma;
      _movedAt = now;
    }
  }

  double? _restBeta, _restGamma;
  double _movedAt = double.negativeInfinity;

  static double _apart(double a, double b) => (a - b).abs();

  /// The tilt drives while the phone is being moved: its angle has changed
  /// by more than [PointerConfig.tiltMoved] within [PointerConfig.tiltRest]
  /// seconds. Judged by the angle, not by when readings arrive: browsers
  /// differ (the ROG's Chrome sent one reading and then nothing for a phone
  /// lying still). A phone at rest is no tilt: the drift takes over.
  bool _tiltLive(double now) =>
      _beta != null && now - _movedAt <= PointerConfig.tiltRest;

  /// Which source drives the pointer at [now].
  PointerSource sourceAt(double now) {
    if (_finger != null) return PointerSource.touch;
    if (!phone && _mouse != null) {
      if (reducedMotion) return PointerSource.mouse;
      if (now - _mouseAt < PointerConfig.mouseIdle) return PointerSource.mouse;
    }
    if (reducedMotion) return PointerSource.still;
    if (phone) {
      return _tiltLive(now) ? PointerSource.tilt : PointerSource.drift;
    }
    // A desktop whose mouse has not moved: the centre, until it has been
    // idle as long as a mouse at rest would be.
    final idleSince = _mouse == null ? _sceneAt : _mouseAt;
    return now - idleSince < PointerConfig.mouseIdle
        ? PointerSource.still
        : PointerSource.drift;
  }

  /// Where the pointer is at [now] on [viewport]: the target to hand the
  /// tracker this frame.
  Vector2 target(double now, Vector2 viewport) {
    final source = sourceAt(now);
    if (source != _source) {
      // A finger or a mouse takes over at once; a virtual source is
      // travelled to from wherever the pointer was.
      final direct =
          source == PointerSource.touch || source == PointerSource.mouse;
      _handFrom = direct || _source == null ? null : _last.clone();
      _handAt = now;
      if (source == PointerSource.drift) _driftFrom = now;
      _source = source;
    }
    final travel = PointerConfig.travelFor(viewport.x, viewport.y);
    final raw = switch (source) {
      PointerSource.touch => _finger!.clone(),
      PointerSource.mouse => _mouse!.clone(),
      PointerSource.tilt => TiltPointer.at(
        beta: _beta!,
        gamma: _gamma!,
        baseBeta: _baseBeta!,
        baseGamma: _baseGamma!,
        viewport: viewport,
        screenAngle: _screenAngle,
        travel: travel,
      ),
      PointerSource.drift => DriftPath.at(
        now - _driftFrom,
        viewport,
        travel: travel,
      ),
      PointerSource.still => viewport / 2,
    };
    final from = _handFrom;
    if (from != null) {
      final t = (now - _handAt) / PointerConfig.handover;
      if (t >= 1) {
        _handFrom = null;
      } else {
        raw.setFrom(from + (raw - from) * Curves.easeInOut.transform(t));
      }
    }
    _last = raw.clone();
    return raw;
  }
}
