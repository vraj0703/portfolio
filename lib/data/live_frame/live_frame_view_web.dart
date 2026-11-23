import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// The live site in an iframe (a Flutter web platform view), laid out at
/// the capture's own page size ([virtualWidth] x [virtualHeight]) and scaled
/// down to the card by a CSS transform from its top-left corner, so it shows
/// the same layout as the picture under it; pointer events map through the
/// transform. It starts transparent and fades itself in by CSS once loaded;
/// a platform view's own opacity is not something Flutter composites
/// reliably. Each mount is a new iframe, and unmounting removes it.
class LiveFrameView extends StatelessWidget {
  const LiveFrameView({
    required this.url,
    required this.onLoaded,
    required this.fade,
    required this.virtualWidth,
    required this.virtualHeight,
    required this.scale,
    super.key,
  });

  final String url;
  final VoidCallback onLoaded;
  final Duration fade;
  final int virtualWidth;
  final int virtualHeight;

  /// The card's width on the screen over [virtualWidth].
  final double scale;

  static final Set<String> _registered = <String>{};
  static final Map<String, VoidCallback> _onLoaded = <String, VoidCallback>{};
  static final Map<String, web.HTMLIFrameElement> _frames =
      <String, web.HTMLIFrameElement>{};

  @override
  Widget build(BuildContext context) {
    final type = 'live-frame:$url';
    _onLoaded[type] = onLoaded;
    if (_registered.add(type)) {
      ui_web.platformViewRegistry.registerViewFactory(type, (int _) {
        final frame = web.HTMLIFrameElement()
          ..src = url
          ..title = url
          ..style.border = '0'
          ..style.width = '${virtualWidth}px'
          ..style.height = '${virtualHeight}px'
          ..style.transformOrigin = '0 0'
          ..style.opacity = '0'
          ..style.transition = 'opacity ${fade.inMilliseconds}ms ease';
        frame.addEventListener(
          'load',
          ((web.Event _) {
            frame.style.opacity = '1';
            _onLoaded[type]?.call();
          }).toJS,
        );
        _frames[type] = frame;
        _scale(frame, _scales[type] ?? scale);
        return frame;
      });
    }
    _scales[type] = scale;
    final frame = _frames[type];
    if (frame != null) _scale(frame, scale);
    return HtmlElementView(viewType: type);
  }

  static final Map<String, double> _scales = <String, double>{};

  static void _scale(web.HTMLIFrameElement frame, double s) {
    frame.style.transform = 'scale($s)';
  }
}
