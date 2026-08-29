import 'dart:math' as math;


/// The word that tells the visitor the corridor is walkable.
///
/// Hung just inside the entrance, and the only instruction the gallery gives.
/// A corridor that does not move until you scroll, with nothing saying so,
/// reads as a still image.
///
/// Pure animation, drawn by the view rather than mounted in the scene.
///
/// It began as a widget on a surface in the room, which was the wrong trade
/// twice over: a `WidgetComponent` rasterises on its update policy whether
/// or not its node is visible, so a hidden cue still cost a capture every
/// frame inside the render loop — and with the manual policy it never
/// rasterised at all, so the cost bought a surface nobody could see. As a
/// value the view reads, it costs nothing and is testable without a GPU.
class ThresholdCue {
  ThresholdCue();

  /// Where the cue sits above the bottom of the view, as a fraction of its
  /// height.
  static const double heightAboveFloor = 1.15;
  static const double distanceIn = -1.5;

  /// How far it lunges toward the visitor, as a fraction of its own size.
  static const double beckonDepth = 0.22;

  /// Beats per second of the beckon.
  static const double beckonRate = 1.8;

  /// After this long without the visitor moving, the cue starts asking more
  /// insistently — the point at which someone has plainly not realised the
  /// corridor is theirs to walk.
  static const double idleAfterSeconds = 4;

  /// Ceiling on how insistent it gets. Beyond this it reads as a fault
  /// rather than an invitation.
  static const double maxIdleGain = 0.6;

  /// How much the cue is currently leaning toward the visitor, `-1..1`.
  double get beckon => _beckon;
  double _beckon = 0;

  /// Whether the cue still has anything to say.
  bool get visible => _visible;
  bool _visible = true;

  /// Advances the beckon.
  ///
  /// [elapsed] is seconds since the corridor opened, [progress] how far the
  /// visitor has walked. The cue stops asking the moment they start moving.
  void update(double elapsed, double progress) {
    final hasMoved = progress > 0.01;

    // Idle only counts while they have not moved; the escalation is a
    // response to hesitation, not a timer that runs regardless.
    final idle = hasMoved ? 0.0 : math.max(0, elapsed - idleAfterSeconds);
    final gain = 1 + math.min(idle * 0.08, maxIdleGain);

    // Asymmetric: a quick lunge toward the visitor and a slow drift back,
    // which reads as beckoning. A plain sine reads as a float.
    final raw = math.sin(elapsed * beckonRate);
    final skewed = raw > 0
        ? math.pow(raw, 0.6).toDouble()
        : -math.pow(-raw, 1.4).toDouble();

    _beckon = skewed * gain;

    // Fades out as the visitor commits, rather than following them down the
    // corridor repeating itself.
    _visible = progress < 0.06;
  }
}
