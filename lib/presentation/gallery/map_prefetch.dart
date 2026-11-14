import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

/// Fetches the gallery's texture files ahead of their decodes, a few at a
/// time (PORTFOLIO-8).
///
/// The build decodes and uploads one map after another, and each decode used
/// to start its own download and wait for it: 31 files, each a round trip
/// and a transfer, end to end, while the network sat idle through every
/// decode and upload between them. At 4x CPU on Fast 4G that was 8 to 10 s
/// of the build spent waiting on bytes.
///
/// [start] is called once, before the shader bundle loads, with every file
/// the build will read in the order it reads them. Downloads then run
/// [parallel] at a time behind the build, and [load] hands over bytes that
/// are usually already here. The loading bar does not move for any of this:
/// it still counts decodes and uploads, the work that ends when the room is
/// ready, so it cannot run ahead of the build.
class MapPrefetch {
  MapPrefetch({
    this.parallel = defaultParallel,
    Future<ByteData> Function(String asset)? fetch,
  }) : _fetch = fetch ?? rootBundle.load;

  /// Downloads in flight at once.
  ///
  /// Four, not six: over HTTP/1.1 a browser opens six connections to a host,
  /// and the shader bundle the build waits on first comes from the same
  /// host. Six prefetches would queue it behind textures nobody needs yet.
  static const int defaultParallel = 4;

  /// The one the gallery build uses. Static because the build is: it runs
  /// once for the life of the app.
  static final MapPrefetch shared = MapPrefetch();

  final int parallel;
  final Future<ByteData> Function(String asset) _fetch;

  final Map<String, Completer<ByteData>> _pending = <String, Completer<ByteData>>{};

  /// How many more times each file will be asked for. A surface listed twice
  /// (the side and hall walls share one set) is fetched once and handed over
  /// twice, then forgotten.
  final Map<String, int> _uses = <String, int>{};

  final Queue<String> _queue = Queue<String>();
  int _running = 0;

  /// Starts fetching [assets], in order, [parallel] at a time.
  void start(Iterable<String> assets) {
    for (final asset in assets) {
      _uses[asset] = (_uses[asset] ?? 0) + 1;
      if (_pending.containsKey(asset)) continue;
      _pending[asset] = Completer<ByteData>();
      _queue.add(asset);
    }
    _pump();
  }

  void _pump() {
    while (_running < parallel && _queue.isNotEmpty) {
      final asset = _queue.removeFirst();
      final completer = _pending[asset]!;
      _running++;
      // Errors go to whoever loads this file, and only to them: one missing
      // map is one surface falling back, not the room.
      _fetch(asset).then(completer.complete, onError: completer.completeError).whenComplete(() {
        _running--;
        _pump();
      });
    }
  }

  /// The bytes of [asset]: the prefetched ones if [start] named it, a fetch
  /// of its own if not.
  Future<ByteData> load(String asset) {
    final completer = _pending[asset];
    if (completer == null) return _fetch(asset);
    final left = (_uses[asset] ?? 1) - 1;
    if (left <= 0) {
      _pending.remove(asset);
      _uses.remove(asset);
    } else {
      _uses[asset] = left;
    }
    return completer.future;
  }

  /// Files fetched or queued and not yet handed over: none, once the build
  /// has read everything it named.
  int get outstanding => _pending.length;
}
