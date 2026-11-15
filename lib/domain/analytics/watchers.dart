import 'dart:math' as math;

/// One scene visit's frames, folded into a summary (`scene_health`).
///
/// A histogram of whole milliseconds, not a list: a long visit at sixty
/// frames a second would otherwise hold tens of thousands of numbers to
/// send seven. Pure, so the folding can be tested without a clock.
class SceneHealthMeter {
  SceneHealthMeter();

  /// Frames slower than this count as slow; slower than [stall], as stalls.
  static const double slow = 50;
  static const double stall = 500;

  /// A visit shorter than this sends nothing: too short to say anything.
  static const double minimumSeconds = 3;

  static const int _buckets = 1001;
  final List<int> _histogram = List<int>.filled(_buckets, 0);

  String? _scene;
  double _seconds = 0;
  int _frames = 0;
  int _slow = 0;
  int _stalls = 0;
  double _worst = 0;
  bool _sent = false;

  String? get scene => _scene;

  /// Starts a new visit to [scene], dropping the last one's numbers.
  void begin(String scene) {
    _scene = scene;
    _seconds = 0;
    _frames = 0;
    _slow = 0;
    _stalls = 0;
    _worst = 0;
    _sent = false;
    _histogram.fillRange(0, _buckets, 0);
  }

  /// One frame took [ms].
  void frame(double ms) {
    if (_scene == null || ms <= 0) return;
    _frames++;
    _seconds += ms / 1000;
    if (ms > slow) _slow++;
    if (ms > stall) _stalls++;
    _worst = math.max(_worst, ms);
    _histogram[math.min(ms.round(), _buckets - 1)]++;
  }

  /// The visit's summary, once: null if it was too short, or already sent.
  /// At most one per visit, whether it ends by leaving or by hiding.
  Map<String, Object?>? take() {
    if (_scene == null || _sent || _seconds < minimumSeconds) return null;
    _sent = true;
    return <String, Object?>{
      'scene': _scene,
      'seconds': double.parse(_seconds.toStringAsFixed(1)),
      'frames': _frames,
      'frame_ms_p50': _percentile(0.5),
      'frame_ms_p95': _percentile(0.95),
      'slow_frames': _slow,
      'stalls': _stalls,
      'worst_frame_ms': _worst.round(),
    };
  }

  int _percentile(double p) {
    final target = (_frames * p).ceil();
    var seen = 0;
    for (var ms = 0; ms < _buckets; ms++) {
      seen += _histogram[ms];
      if (seen >= target) return ms;
    }
    return _buckets - 1;
  }
}

/// Stalls of the main thread long enough to be the web's nearest thing to
/// an ANR (`hang`), at most [cap] a visit.
class HangWatch {
  HangWatch();

  static const int threshold = 2000;
  static const int cap = 5;

  int _sent = 0;

  /// Whether a stall of [ms] is reported. Counts what it lets through.
  bool admit(int ms) {
    if (ms < threshold || _sent >= cap) return false;
    _sent++;
    return true;
  }
}

/// Whether the visitor got in (`site_loaded`) or gave up on the way
/// (`load_abandoned`): exactly one of the two, once.
class LoadWatch {
  LoadWatch();

  bool _loaded = false;
  bool _abandoned = false;

  bool get loaded => _loaded;

  /// The title took input. True the first time only.
  bool arrive() {
    if (_loaded || _abandoned) return false;
    _loaded = true;
    return true;
  }

  /// The page is going away. True if the visitor never got in, the first
  /// time only; after `site_loaded` a hidden page is not an abandonment.
  bool leave() {
    if (_loaded || _abandoned) return false;
    _abandoned = true;
    return true;
  }
}
