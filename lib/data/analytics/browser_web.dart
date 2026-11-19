import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// What the browser will say about itself and about the page's timing, for
/// `site_loaded` and `load_abandoned`. Each is null when the browser does
/// not tell.
abstract final class Browser {
  /// Milliseconds since navigation started.
  static double now() => web.window.performance.now();

  /// A named mark on the page's performance timeline: where the visitor is,
  /// for the end-to-end journey check (tool/check_journey.py) and for a
  /// trace. A few dozen bytes per scene; nothing reads it in production.
  static void mark(String name) => web.window.performance.mark(name);

  static double? firstPaint() {
    final entries = web.window.performance.getEntriesByName(
      'first-contentful-paint',
    );
    if (entries.length == 0) return null;
    return entries.toDart.first.startTime;
  }

  static int? cores() {
    final n = web.window.navigator.hardwareConcurrency;
    return n > 0 ? n : null;
  }

  static double? memoryGb() {
    final v = web.window.navigator.getProperty<JSAny?>('deviceMemory'.toJS);
    return v != null && v.isA<JSNumber>() ? (v as JSNumber).toDartDouble : null;
  }

  static String? connection() {
    final c = web.window.navigator.getProperty<JSObject?>('connection'.toJS);
    final t = c?.getProperty<JSAny?>('effectiveType'.toJS);
    return t != null && t.isA<JSString>() ? (t as JSString).toDart : null;
  }

  /// Whether this is a phone: a coarse pointer and a screen whose short side
  /// is at most [phoneShortSide] CSS pixels. By what the device is rather
  /// than what it is called; desktops and tablets answer false.
  static bool isPhone() {
    final coarse = web.window.matchMedia('(pointer: coarse)').matches;
    final screen = web.window.screen;
    final shortSide = screen.width < screen.height
        ? screen.width
        : screen.height;
    return coarse && shortSide <= phoneShortSide;
  }

  /// The largest short side, in CSS pixels, that still counts as a phone.
  static const int phoneShortSide = 600;

  /// The GPU's name, as WebGL reports it.
  static String? renderer() {
    try {
      final canvas = web.HTMLCanvasElement();
      final gl = canvas.getContext('webgl') as web.WebGLRenderingContext?;
      if (gl == null) return null;
      final info = gl.getExtension('WEBGL_debug_renderer_info');
      final param = info == null
          ? web.WebGLRenderingContext.RENDERER
          : 0x9246; // UNMASKED_RENDERER_WEBGL
      final v = gl.getParameter(param);
      gl
          .getExtension('WEBGL_lose_context')
          ?.callMethod<JSAny?>('loseContext'.toJS);
      return v != null && v.isA<JSString>() ? (v as JSString).toDart : null;
    } catch (_) {
      return null;
    }
  }

  static bool get visible => web.document.visibilityState != 'hidden';

  /// Calls [onHide] when the page is hidden (a tab switch, a phone locked)
  /// and [onLeave] when it is being closed or navigated away from.
  static void watch({
    required void Function() onHide,
    required void Function() onLeave,
  }) {
    web.document.addEventListener(
      'visibilitychange',
      ((web.Event _) {
        if (!visible) onHide();
      }).toJS,
    );
    web.window.addEventListener('pagehide', ((web.Event _) => onLeave()).toJS);
  }
}
