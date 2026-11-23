import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// One iframe of the site at its virtual page size, in a full-screen layer
/// above the canvas, laid onto the card each frame by a CSS matrix3d (the
/// way three.js's CSS3DRenderer does): the transform is set straight on the
/// element from the gallery's tick, with no widget rebuild. It takes no
/// pointer input: in the corridor the visitor walks, and a focused frame
/// hands over to the axis-aligned live layer.
abstract final class CorridorFrame {
  static final Set<String> _registered = <String>{};
  static web.HTMLIFrameElement? _frame;
  static List<double>? _pending;
  static double _opacity = 0;

  static int? _loadedMs;

  /// Milliseconds from the view's creation to its page's load, once loaded.
  static int? get loadedMs => _loadedMs;

  static Widget view(
    String url,
    int width,
    int height, {
    required String tint,
  }) {
    final type = 'corridor-frame:$url';
    if (_registered.add(type)) {
      ui_web.platformViewRegistry.registerViewFactory(type, (int _) {
        final root = web.HTMLDivElement()
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.overflow = 'hidden'
          ..style.pointerEvents = 'none';
        final asked = DateTime.now();
        final frame = web.HTMLIFrameElement()
          ..src = url
          ..setAttribute('data-live', 'corridor')
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
          // visibility, which keeps the page laid out, rather than display,
          // which would lay out 1424 x 1024 again each time it shows.
          ..style.willChange = 'transform, opacity'
          ..style.visibility = 'hidden';
        frame.onLoad.first.then((_) {
          _loadedMs = DateTime.now().difference(asked).inMilliseconds;
        });
        root.append(frame);
        _frame = frame;
        place(_pending, opacity: _opacity);
        return root;
      });
    }
    return HtmlElementView(viewType: type);
  }

  /// Lays the page onto the card ([matrix], column-major matrix3d), or hides
  /// it (null). [opacity] cross-fades it over the picture.
  static void place(List<double>? matrix, {double opacity = 1}) {
    _pending = matrix;
    _opacity = opacity;
    final frame = _frame;
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
