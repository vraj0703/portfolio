import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:portfolio/domain/gallery/gallery_dimensions.dart';
import 'package:portfolio/presentation/gallery/scene_axes.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// The word that tells the visitor the corridor is walkable.
///
/// Hung just inside the entrance, and the only instruction the gallery gives.
/// A corridor that does not move until you scroll, with nothing saying so,
/// reads as a still image.
///
/// Built as a Flutter widget on a surface in the scene rather than as 3D
/// text: flutter_scene has no glyph rendering of its own, and this way the
/// cue is set in the app's own type, at any size, with no font atlas to
/// bake. The same mechanism carries the testimonial cards and the keycaps.
class ThresholdCue {
  ThresholdCue._(this._node);

  final Node _node;

  Node get node => _node;

  /// Where the cue hangs, in design coordinates.
  static const double heightAboveFloor = 1.15;
  static const double distanceIn = -1.5;

  /// How far it lunges toward the visitor, in world units.
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

  static ThresholdCue build({required TextStyle style}) {
    final node = Node(
      localTransform: vm.Matrix4.translation(
        SceneAxes.position(
          vm.Vector3(
            0,
            GalleryDimensions.floorY + heightAboveFloor,
            distanceIn,
          ),
        ),
      ),
    );

    node.addComponent(
      WidgetComponent(
        // Captured once. The word never changes, and re-rasterising static
        // text every frame costs a full widget capture for an identical
        // result — the motion lives in the node's transform, not in the
        // pixels.
        update: WidgetUpdatePolicy.manual,
        // It is a sign, not a button. Automatic forwarding would let it
        // swallow pointer events aimed at the corridor behind it.
        input: WidgetInput.manual,
        size: const Size(420, 120),
        worldHeight: 0.42,
        child: Center(child: Text('SCROLL', style: style)),
      ),
    );

    return ThresholdCue._(node);
  }

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

    final z = distanceIn + skewed * beckonDepth * gain;
    final lift = math.max(0.0, math.sin(elapsed * beckonRate + 0.3)) * 0.015 * gain;

    _node.localTransform = vm.Matrix4.translation(
      SceneAxes.position(
        vm.Vector3(0, GalleryDimensions.floorY + heightAboveFloor + lift, z),
      ),
    );

    // Fades out as the visitor commits, rather than following them down the
    // corridor repeating itself.
    _node.visible = progress < 0.06;
  }
}
