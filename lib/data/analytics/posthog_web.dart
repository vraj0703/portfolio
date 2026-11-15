import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:portfolio/domain/analytics/analytics.dart';
import 'package:web/web.dart' as web;

/// PostHog in the browser, over the SDK's own snippet (`web/index.html`)
/// through `dart:js_interop`. No Dart package: the SDK is a script, and the
/// snippet's stub already queues every call made before it arrives.
///
/// Nothing is fetched until [start], which the app calls after its first
/// frame; the snippet only defines `window.posthog` until then. Options are
/// the ones PostHog documents for posthog-js (checked 2026-11-15 against
/// posthog.com/docs/libraries/js/config): cookieless, no autocapture, no
/// automatic page views (one per scene is sent instead), no recordings,
/// exceptions captured.
class PostHogAnalytics implements Analytics {
  PostHogAnalytics({required this.token, required this.host});

  final String token;
  final String host;

  final ChangeNotifier _flags = ChangeNotifier();
  bool _started = false;

  /// Calls made before [start]. The snippet's stub only grows its methods
  /// when init runs, so until then the calls wait here, in order, and are
  /// replayed straight after it.
  final List<void Function(JSObject)> _pending = <void Function(JSObject)>[];

  void _call(void Function(JSObject) call) {
    final ph = _ph;
    if (ph == null || token.isEmpty) return;
    if (_started) {
      call(ph);
    } else if (_pending.length < 200) {
      _pending.add(call);
    }
  }

  JSObject? get _ph => web.window.getProperty<JSObject?>('posthog'.toJS);

  /// Loads the SDK. Call once, after the first frame: the first paint never
  /// waits on it.
  void start() {
    final ph = _ph;
    if (_started || ph == null || token.isEmpty) return;
    _started = true;
    ph.callMethod<JSAny?>(
      'init'.toJS,
      token.toJS,
      <String, Object?>{
        'api_host': host,
        'defaults': '2026-08-30',
        // Nothing stored, no cookies, no banner (the plan's default). The
        // project setting must be switched on too, or PostHog drops these.
        'cookieless_mode': 'always',
        'autocapture': false,
        'capture_pageview': false,
        'capture_pageleave': false,
        'disable_session_recording': true,
        'capture_exceptions': true,
        // Nothing is written onto a visitor (the plan): no person profiles,
        // so the SDK sends no $set of its own.
        'person_profiles': 'never',
      }.jsify(),
    );
    ph.callMethod<JSAny?>(
      'onFeatureFlags'.toJS,
      (() {
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        _flags.notifyListeners();
      }).toJS,
    );
    for (final call in _pending) {
      call(ph);
    }
    _pending.clear();
  }

  @override
  void capture(
    String event,
    Map<String, Object?> properties, {
    bool beforeUnload = false,
  }) {
    _call(
      (ph) => ph.callMethod<JSAny?>(
        'capture'.toJS,
        event.toJS,
        properties.jsify(),
        beforeUnload
            ? <String, Object?>{
                'transport': 'sendBeacon',
                'send_instantly': true,
              }.jsify()
            : null,
      ),
    );
  }

  @override
  void screen(String path, Map<String, Object?> properties) {
    // The scene rides in the URL PostHog records, so its paths, web
    // analytics and heatmaps read it with nothing bespoke; the address bar
    // itself is not changed.
    final origin = web.window.location.origin;
    capture(SiteEvents.pageview, <String, Object?>{
      ...properties,
      r'$current_url': '$origin/$path'.replaceFirst('//#', '/#'),
    });
  }

  @override
  bool flag(String key, {required bool orElse}) {
    final ph = _ph;
    if (ph == null || !_started) return orElse;
    // send_event: false, or every read of a flag is an event of its own
    // ($feature_flag_called), outside the plan's fifteen.
    final value = ph.callMethod<JSAny?>(
      'isFeatureEnabled'.toJS,
      key.toJS,
      <String, Object?>{'send_event': false}.jsify(),
    );
    if (value == null || !value.isA<JSBoolean>()) return orElse;
    return (value as JSBoolean).toDart;
  }

  @override
  Listenable get flagsChanged => _flags;

  @override
  void captureException(Object error, StackTrace? stack) {
    _call((ph) {
      final jsError = web.window
          .getProperty<JSFunction>('Error'.toJS)
          .callAsConstructor<JSObject>(error.toString().toJS);
      if (stack != null) {
        jsError.setProperty('stack'.toJS, stack.toString().toJS);
      }
      ph.callMethod<JSAny?>('captureException'.toJS, jsError);
    });
  }
}
