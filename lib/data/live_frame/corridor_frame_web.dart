import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// One iframe per live frame, each its site at the virtual page size, in ONE
/// full-screen layer above the canvas (one platform view however many frames
/// are live), each laid onto its card every frame by a CSS matrix3d (the way
/// three.js's CSS3DRenderer does): the transform is set straight on the
/// element from the gallery's tick, with no widget rebuild. They take no
/// pointer input: in the corridor the visitor walks, and a focused frame
/// hands over to the axis-aligned live layer.
abstract final class CorridorFrame {
  static final Set<String> _registered = <String>{};
  static final Map<String, web.HTMLIFrameElement> _frames =
      <String, web.HTMLIFrameElement>{};
  static final Map<String, (List<double>?, double)> _pending =
      <String, (List<double>?, double)>{};
  static final Map<String, int> _loadedMs = <String, int>{};

  /// Milliseconds from the view's creation to frame [id]'s page load, once
  /// loaded.
  static int? loadedMs(String id) => _loadedMs[id];

  /// The layer for [sites] (frame id to its live page, in corridor order).
  static Widget view(
    Map<String, String> sites,
    int width,
    int height, {
    required String tint,
  }) {
    final type = 'corridor-frames:${sites.values.join('|')}';
    if (_registered.add(type)) {
      ui_web.platformViewRegistry.registerViewFactory(type, (int _) {
        final root = web.HTMLDivElement()
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.overflow = 'hidden'
          ..style.pointerEvents = 'none';
        final asked = DateTime.now();
        for (final MapEntry(key: id, value: url) in sites.entries) {
          final frame = web.HTMLIFrameElement()
            ..src = url
            ..setAttribute('data-live', 'corridor')
            ..setAttribute('data-id', id)
            ..style.position = 'absolute'
            ..style.left = '0'
            ..style.top = '0'
            ..style.border = '0'
            ..style.width = '${width}px'
            ..style.height = '${height}px'
            ..style.transformOrigin = '0 0'
            ..style.pointerEvents = 'none'
            ..style.filter = tint
            // Its own compositor layer, rastered once and moved by the GPU,
            // rather than re-rastered at every new transform; and hidden by
            // visibility, which keeps the page laid out, rather than
            // display, which would lay out 1424 x 1024 again each time it
            // shows.
            ..style.willChange = 'transform, opacity'
            ..style.visibility = 'hidden';
          frame.onLoad.first.then((_) {
            _loadedMs[id] = DateTime.now().difference(asked).inMilliseconds;
          });
          root.append(frame);
          _frames[id] = frame;
          final (matrix, opacity) = _pending[id] ?? (null, 0.0);
          place(id, matrix, opacity: opacity);
        }
        return root;
      });
    }
    return HtmlElementView(viewType: type);
  }

  /// Lays frame [id]'s page onto its card ([matrix], column-major
  /// matrix3d), or hides it (null). [opacity] cross-fades it over the
  /// picture.
  static void place(String id, List<double>? matrix, {double opacity = 1}) {
    _pending[id] = (matrix, opacity);
    final frame = _frames[id];
    if (frame == null) return;
    if (matrix == null || opacity <= 0.001) {
      frame.style.visibility = 'hidden';
      return;
    }
    frame.style
      ..visibility = 'visible'
      ..opacity = opacity.toStringAsFixed(3)
      ..transform =
          'matrix3d(${matrix.map((v) => v.toStringAsFixed(6)).join(',')})';
  }
}
