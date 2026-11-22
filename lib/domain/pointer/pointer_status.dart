import 'package:portfolio/domain/pointer/pointer_path.dart';

/// What the analytics say about the pointer (PORTFOLIO-27): which source
/// drove it, and what became of the motion permission. Written by the
/// game's pointer adapter, read by `SiteEvents`; one shared instance (DI).
class PointerStatus {
  /// The source driving the pointer now.
  PointerSource source = PointerSource.still;

  /// What became of the iPhone's motion permission.
  TiltPermission permission = TiltPermission.notNeeded;

  final Map<PointerSource, double> _seconds = <PointerSource, double>{};

  /// The adapter's frame: [source] drove the pointer for [dt] seconds.
  void note(PointerSource source, double dt) {
    this.source = source;
    _seconds[source] = (_seconds[source] ?? 0) + dt;
  }

  /// The source that drove the pointer longest since the last call, or the
  /// current one when nothing was noted; and starts counting afresh. One
  /// scene visit's answer, for `scene_health`.
  PointerSource takeScene() {
    var best = source;
    var most = -1.0;
    _seconds.forEach((s, t) {
      if (t > most) {
        most = t;
        best = s;
      }
    });
    _seconds.clear();
    return best;
  }

  /// The properties `site_loaded` carries: the source now.
  Map<String, Object?> get now => <String, Object?>{
    'pointer_source': source.name,
    'tilt_permission': permission.wire,
  };

  /// The properties `scene_health` carries: the scene's main source.
  Map<String, Object?> scene() => <String, Object?>{
    'pointer_source': takeScene().name,
    'tilt_permission': permission.wire,
  };
}
