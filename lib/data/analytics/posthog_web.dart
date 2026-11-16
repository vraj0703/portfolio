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
/// posthog.com/docs/libraries/js/config, re-checked 2026-11-16): an
/// anonymous id in localStorage and no cookie, no autocapture, no
/// automatic page views (one per scene is sent instead), no recordings,
/// exceptions captured.
class PostHogAnalytics implements Analytics {
  PostHogAnalytics({required this.token, required this.host});

  final String token;
  final String host;

  final ChangeNotifier _flags = ChangeNotifier();
  bool _started = false;

  /// The browser declined tracking; nothing is ever sent.
  bool _declined = false;

  /// Counts this visit in localStorage. Storage can be refused (a private
  /// window, blocked site data): then it is visit 1, and nothing breaks.
  int _nextVisit() {
    try {
      final storage = web.window.localStorage;
      final n = VisitCounter.next(storage.getItem(VisitCounter.key));
      storage.setItem(VisitCounter.key, '$n');
      return n;
    } catch (_) {
      return 1;
    }
  }

  /// Calls made before [start]. The snippet's stub only grows its methods
  /// when init runs, so until then the calls wait here, in order, and are
  /// replayed straight after it.
  final List<void Function(JSObject)> _pending = <void Function(JSObject)>[];

  void _call(void Function(JSObject) call) {
    final ph = _ph;
    if (ph == null || token.isEmpty || _declined) return;
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
    if (_started || _declined || ph == null || token.isEmpty) return;
    // The browser has asked not to be tracked: nothing loads, nothing is
    // stored, nothing is sent, and every flag keeps its default.
    final navigator = web.window.navigator;
    final dnt = navigator.getProperty<JSAny?>('doNotTrack'.toJS);
    final gpc = navigator.getProperty<JSAny?>('globalPrivacyControl'.toJS);
    if (PrivacySignals.decline(
      doNotTrack: dnt != null && dnt.isA<JSString>()
          ? (dnt as JSString).toDart
          : null,
      globalPrivacyControl: gpc != null && gpc.isA<JSBoolean>()
          ? (gpc as JSBoolean).toDart
          : null,
    )) {
      _declined = true;
      _pending.clear();
      return;
    }
    _started = true;
    ph.callMethod<JSAny?>(
      'init'.toJS,
      token.toJS,
      <String, Object?>{
        'api_host': host,
        'defaults': '2026-08-30',
        // An anonymous id in localStorage, and no cookie (Vishal's
        // decision, 2026-11-16), so a return visit is the same visitor.
        'persistence': 'localStorage',
        // Belt and braces: the app already stays out when Do Not Track or
        // Global Privacy Control is on (see [start]); PostHog's own check
        // covers Do Not Track only.
        'respect_dnt': true,
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
    // This visit's number, beside the anonymous id, on every event from
    // here on (a super property), the queued ones included.
    ph.callMethod<JSAny?>(
      'register'.toJS,
      <String, Object?>{'visit_number': _nextVisit()}.jsify(),
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
