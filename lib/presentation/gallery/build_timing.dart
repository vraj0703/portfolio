import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show debugPrint;

/// Where the gallery's build spends its time, phase by phase (PORTFOLIO-8).
///
/// Off unless the app is built with `--dart-define=BUILD_TIMING=true`; the
/// constant folds every call away in the site visitors get. On, each phase
/// adds up its own wall time and the table is printed to the console once,
/// when the warm render under the curtain has finished.
///
/// **Exclusive, not inclusive.** A span opened inside another pauses the
/// outer one, so a frame yielded in the middle of a repack is counted as
/// [BuildPhase.frames], not as repacking, and the rows add up to the whole.
/// The build is sequential (each step awaits the last), so one current
/// phase is enough to attribute every millisecond.
abstract final class BuildTiming {
  static const bool enabled = bool.fromEnvironment('BUILD_TIMING');

  static final Map<BuildPhase, Duration> _totals = <BuildPhase, Duration>{};
  static final Map<BuildPhase, int> _counts = <BuildPhase, int>{};
  static final Stopwatch _clock = Stopwatch();
  static BuildPhase _current = BuildPhase.other;
  static Duration _mark = Duration.zero;
  static bool _printed = false;
  static final List<String> _uploads = <String>[];

  /// Starts the clock: the build has begun.
  static void start() {
    if (!enabled || _clock.isRunning) return;
    _clock.start();
    _mark = Duration.zero;
    _current = BuildPhase.other;
  }

  /// Runs [body] as [phase], pausing whatever phase was running.
  static Future<T> span<T>(BuildPhase phase, Future<T> Function() body) async {
    if (!enabled || !_clock.isRunning) return body();
    final outer = _current;
    _switchTo(phase);
    _counts[phase] = (_counts[phase] ?? 0) + 1;
    try {
      return await body();
    } finally {
      _switchTo(outer);
    }
  }

  /// Runs [body] as [BuildPhase.upload] and notes [what], [image]'s size and
  /// the time it took, listed under the table: the upload row alone does not
  /// say which textures it is made of.
  static Future<T> upload<T>(
    String what,
    ui.Image image,
    Future<T> Function() body,
  ) async {
    if (!enabled || !_clock.isRunning) return body();
    final size = '${image.width}x${image.height}';
    final watch = Stopwatch()..start();
    try {
      return await span(BuildPhase.upload, body);
    } finally {
      _uploads.add('[build] upload $what $size ${watch.elapsedMilliseconds} ms');
    }
  }

  /// Switches to [phase] from here on, for work that spans frames rather
  /// than one awaited call (the warm render).
  static void mark(BuildPhase phase) {
    if (!enabled || !_clock.isRunning) return;
    if (_current != phase) _counts[phase] = (_counts[phase] ?? 0) + 1;
    _switchTo(phase);
  }

  static void _switchTo(BuildPhase next) {
    final now = _clock.elapsed;
    _totals[_current] = (_totals[_current] ?? Duration.zero) + (now - _mark);
    _mark = now;
    _current = next;
  }

  /// Ends the clock and prints the table: the warm render has finished.
  static void finish() {
    if (!enabled || !_clock.isRunning || _printed) return;
    _switchTo(BuildPhase.other);
    _clock.stop();
    _printed = true;
    final total = _clock.elapsed.inMicroseconds / 1000;
    final rows = StringBuffer('[build] phase | ms | share | calls\n');
    for (final phase in BuildPhase.values) {
      final ms = (_totals[phase] ?? Duration.zero).inMicroseconds / 1000;
      if (ms == 0) continue;
      rows.writeln(
        '[build] ${phase.name} | ${ms.toStringAsFixed(0)} | '
        '${(ms / total * 100).toStringAsFixed(1)}% | ${_counts[phase] ?? 0}',
      );
    }
    rows.write('[build] total | ${total.toStringAsFixed(0)} | 100% |');
    for (final line in _uploads) {
      rows.write('\n$line');
    }
    debugPrint(rows.toString());
  }
}

/// What the gallery's build is doing, for [BuildTiming].
enum BuildPhase {
  /// The engine's shader bundles: fetched and brought up.
  shaders,

  /// Asset bytes arriving (`rootBundle.load`): the network, on the web.
  fetch,

  /// Compressed images decoded to pixels.
  decode,

  /// Decoded pixels read back to Dart, for the roughness/metal repack.
  readback,

  /// The roughness/metal repack loop and its re-upload as an image.
  repack,

  /// Images uploaded as GPU textures, mip chain included.
  upload,

  /// Cards and wall lettering painted and rasterised.
  bake,

  /// Frames handed back to the engine so the loading screen keeps drawing.
  frames,

  /// The warm render under the curtain: drawing the room once.
  priming,

  /// Everything else: geometry, models, scene graph, bookkeeping.
  other,
}
