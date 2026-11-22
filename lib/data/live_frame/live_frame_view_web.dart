import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// The live site in an iframe (a Flutter web platform view). It starts
/// transparent and fades itself in by CSS once the page has loaded, so the
/// frame's picture shows until then; a platform view's own opacity is not
/// something Flutter composites reliably. Each mount is a new iframe, and
/// unmounting removes it.
class LiveFrameView extends StatelessWidget {
  const LiveFrameView({
    required this.url,
    required this.onLoaded,
    required this.fade,
    super.key,
  });

  final String url;
  final VoidCallback onLoaded;
  final Duration fade;

  static final Set<String> _registered = <String>{};

  /// The current mount's callback per view type: the factory is registered
  /// once, the widget that mounts it can change.
  static final Map<String, VoidCallback> _onLoaded = <String, VoidCallback>{};

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
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.opacity = '0'
          ..style.transition = 'opacity ${fade.inMilliseconds}ms ease';
        frame.addEventListener(
          'load',
          ((web.Event _) {
            frame.style.opacity = '1';
            _onLoaded[type]?.call();
          }).toJS,
        );
        return frame;
      });
    }
    return HtmlElementView(viewType: type);
  }
}
