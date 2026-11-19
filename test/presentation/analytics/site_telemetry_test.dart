import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/data/analytics/analytics_setup.dart';
import 'package:portfolio/domain/analytics/analytics.dart';
import 'package:portfolio/domain/analytics/watchers.dart';
import 'package:portfolio/domain/config/button_flags.dart';
import 'package:portfolio/domain/models/loading_phase.dart';
import 'package:portfolio/domain/models/loading_progress.dart';
import 'package:portfolio/presentation/analytics/site_telemetry.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';

/// Records what would have been sent.
class Recorder implements Analytics {
  final List<(String, Map<String, Object?>, bool)> sent =
      <(String, Map<String, Object?>, bool)>[];
  final Map<String, bool> flags = <String, bool>{};
  final ChangeNotifier changed = ChangeNotifier();

  List<String> get names => sent.map((e) => e.$1).toList();

  @override
  void capture(
    String event,
    Map<String, Object?> properties, {
    bool beforeUnload = false,
  }) => sent.add((event, properties, beforeUnload));

  @override
  void screen(String path, Map<String, Object?> properties) => sent.add((
    r'$pageview',
    <String, Object?>{...properties, 'path': path},
    false,
  ));

  @override
  bool flag(String key, {required bool orElse}) => flags[key] ?? orElse;

  @override
  Listenable get flagsChanged => changed;

  @override
  void captureException(Object error, StackTrace? stack) =>
      sent.add((r'$exception', <String, Object?>{'error': '$error'}, false));
}

void main() {
  late Recorder sink;
  late SiteEvents events;
  late SiteTelemetry telemetry;
  var clock = 0.0;

  setUp(() {
    sink = Recorder();
    events = SiteEvents(sink, viewport: () => (390, 844));
    clock = 0;
    telemetry = SiteTelemetry(events, now: () => clock);
  });

  group('the plan\'s events are written in one place', () {
    test('every name is in the typed wrapper, and nowhere else in lib/', () {
      final wrapper = File('lib/domain/analytics/analytics.dart').path;
      final others = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => f.path.replaceAll(r'\', '/') != wrapper)
          .toList();
      for (final name in SiteEvents.names) {
        final quoted = RegExp("['\"]${RegExp.escape(name)}['\"]");
        for (final file in others) {
          expect(
            quoted.hasMatch(file.readAsStringSync()),
            isFalse,
            reason: '$name written as a string in ${file.path}',
          );
        }
      }
    });

    test('fifteen from the plan, and the one control it names', () {
      expect(SiteEvents.names, hasLength(16));
      expect(SiteEvents.names, contains('sound_toggled'));
    });

    test('every event carries the scene, the viewport and the device', () {
      events.projectCaseOpened('tantr');
      final props = sink.sent.single.$2;
      expect(props['scene'], SitePath.logo);
      expect(props['viewport'], '390x844');
      expect(props['device_class'], 'phone');
      expect(props['project'], 'tantr');
    });
  });

  group('a build with no token', () {
    test('is silent: nothing is created that could send', () {
      expect(createAnalytics(token: ''), isA<SilentAnalytics>());
    });

    test('every flag is its compiled default', () {
      final silent = SiteEvents(SilentAnalytics(), viewport: () => (1, 1));
      expect(silent.showsConnect(), isTrue);
      expect(silent.showsMenu(), isTrue);
    });
  });

  group('getting in (question 1)', () {
    test('load_abandoned on leaving before the title, by beacon', () {
      telemetry.onScene(
        SceneState.loading(
          progress: const LoadingProgress().advance(LoadingPhase.gallery, 0.3),
        ),
      );
      clock = 4200;
      telemetry.leaving();
      final abandoned = sink.sent.where((e) => e.$1 == 'load_abandoned');
      expect(abandoned, hasLength(1));
      expect(abandoned.single.$2['phase_reached'], 'gallery');
      expect(abandoned.single.$2['ms_waited'], 4200);
      expect(abandoned.single.$3, isTrue, reason: 'sent as the page closes');
    });

    test('site_loaded when the logo first accepts the tap, with ms_ready', () {
      telemetry.onScene(const SceneState.logo());
      expect(sink.names, isNot(contains('site_loaded')));
      clock = 9100;
      telemetry.onScene(const SceneState.logo(isInteractive: true));
      final loaded = sink.sent.where((e) => e.$1 == 'site_loaded').single;
      expect(loaded.$2['ms_ready'], 9100);
      expect(loaded.$2.containsKey('ms_interactive'), isFalse);
    });

    test('not after the logo accepts the tap: then it was site_loaded', () {
      telemetry.onScene(const SceneState.logo(isInteractive: true));
      expect(sink.names, contains('site_loaded'));
      telemetry.leaving();
      expect(sink.names, isNot(contains('load_abandoned')));
    });

    test('site_loaded once, however often the logo comes back', () {
      telemetry
        ..onScene(const SceneState.logo(isInteractive: true))
        ..onScene(const SceneState.title())
        ..onScene(const SceneState.contact())
        ..onScene(const SceneState.logo(isInteractive: true));
      expect(sink.names.where((n) => n == 'site_loaded'), hasLength(1));
    });

    test('and load_abandoned at most once', () {
      telemetry
        ..leaving()
        ..leaving();
      expect(sink.names.where((n) => n == 'load_abandoned'), hasLength(1));
    });
  });

  group('the journey (question 3)', () {
    test('the first scene is announced too, after start', () {
      // The meter starts on the scene the wrapper begins in; that must not
      // read as "already announced".
      telemetry.onScene(const SceneState.logo());
      expect(
        sink.sent.where((e) => e.$1 == r'$pageview').map((e) => e.$2['path']),
        <String>[SitePath.logo],
      );
    });

    test('one page view per scene, with the piece and the wall', () {
      telemetry
        ..onScene(const SceneState.logo())
        ..onScene(const SceneState.title())
        ..onScene(const SceneState.active())
        ..onScene(const SceneState.gallery())
        ..onPiece('tantr')
        ..onPiece(null)
        ..onRegion(SitePath.testimonials)
        ..onRegion(SitePath.testimonials)
        ..onScene(const SceneState.contact());
      final paths = sink.sent
          .where((e) => e.$1 == r'$pageview')
          .map((e) => e.$2['path'])
          .toList();
      expect(paths, <String>[
        SitePath.logo,
        SitePath.title,
        SitePath.gallery,
        SitePath.piece('tantr'),
        SitePath.gallery,
        SitePath.testimonials,
        SitePath.contact,
      ]);
    });
  });

  group('smoothness (question 2)', () {
    test('scene_health once per visit, on leaving the scene', () {
      telemetry.onScene(const SceneState.title());
      for (var i = 0; i < 300; i++) {
        telemetry.frame(i % 50 == 0 ? 120 : 16);
      }
      telemetry.onScene(const SceneState.gallery());
      final health = sink.sent.where((e) => e.$1 == 'scene_health').toList();
      expect(health, hasLength(1));
      expect(health.single.$2['scene'], SitePath.title);
      expect(health.single.$2['frames'], 300);
      expect(health.single.$2['frame_ms_p50'], 16);
      expect(health.single.$2['slow_frames'], 6);
      expect(health.single.$2['worst_frame_ms'], 120);
    });

    test('capped: hiding twice in one visit sends one', () {
      telemetry.onScene(const SceneState.title());
      for (var i = 0; i < 300; i++) {
        telemetry.frame(16);
      }
      telemetry
        ..hidden()
        ..hidden();
      final health = sink.sent.where((e) => e.$1 == 'scene_health').toList();
      expect(health, hasLength(1));
      expect(health.single.$3, isTrue, reason: 'by beacon when hidden');
    });

    test('a visit under three seconds sends nothing', () {
      telemetry.onScene(const SceneState.title());
      for (var i = 0; i < 100; i++) {
        telemetry.frame(16);
      }
      telemetry.onScene(const SceneState.gallery());
      expect(sink.names, isNot(contains('scene_health')));
    });

    test('hang: over two seconds only, five a visit at most', () {
      telemetry.stalled(1999);
      for (var i = 0; i < 8; i++) {
        telemetry.stalled(2500);
      }
      final hangs = sink.sent.where((e) => e.$1 == 'hang').toList();
      expect(hangs, hasLength(HangWatch.cap));
      expect(hangs.first.$2['ms'], 2500);
      expect(hangs.first.$2['during'], isNotEmpty);
    });
  });

  group('the flags', () {
    test('the default holds when the SDK is missing', () {
      expect(SiteEvents(sink, viewport: () => (1, 1)).showsConnect(), isTrue);
      expect(const ButtonFlags(), const ButtonFlags(connect: true, menu: true));
    });

    test('ride on the state, through every transition', () async {
      final bloc = SceneBloc(flags: const ButtonFlags(connect: false));
      addTearDown(bloc.close);
      expect(bloc.state.flags.connect, isFalse);
      bloc.add(const SceneEvent.flagsChanged(flags: ButtonFlags(menu: false)));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.flags, const ButtonFlags(menu: false));
      bloc.add(const SceneEvent.initialize());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      // A handler building a new state without them still carries them.
      expect(bloc.state.flags, const ButtonFlags(menu: false));
    });

    test('the widgets read a rule on the state, not the flag', () {
      const on = SceneState.title();
      const off = SceneState.title(
        flags: ButtonFlags(connect: false, menu: false),
      );
      expect(on.showsConnect && on.showsMenuButton, isTrue);
      expect(off.showsConnect || off.showsMenuButton, isFalse);
      // Off-stage, neither shows whatever the flags say.
      expect(const SceneState.loading().showsConnect, isFalse);
      // The gallery keeps the title's icons (Vishal, 2026-11-18).
      expect(const SceneState.gallery().showsConnect, isTrue);
    });
  });

  group('return visits (stored anonymous id)', () {
    test('visit_number counts up from what was stored', () {
      expect(VisitCounter.next(null), 1, reason: 'a first visit');
      expect(VisitCounter.next('1'), 2);
      expect(VisitCounter.next('41'), 42);
    });

    test('unreadable storage is a first visit, not an error', () {
      expect(VisitCounter.next('not a number'), 1);
      expect(VisitCounter.next('-3'), 1);
    });
  });

  group('the browser privacy signals switch it all off', () {
    test('Do Not Track or Global Privacy Control declines', () {
      expect(PrivacySignals.decline(doNotTrack: '1'), isTrue);
      expect(PrivacySignals.decline(doNotTrack: 'yes'), isTrue);
      expect(PrivacySignals.decline(globalPrivacyControl: true), isTrue);
    });

    test('neither, or a refusal of them, does not', () {
      expect(PrivacySignals.decline(), isFalse);
      expect(PrivacySignals.decline(doNotTrack: '0'), isFalse);
      expect(PrivacySignals.decline(doNotTrack: 'unspecified'), isFalse);
      expect(PrivacySignals.decline(globalPrivacyControl: false), isFalse);
    });
  });

  test('a copied testimonial is measured by its length, never its text', () {
    events.testimonialTextCopied(TextLength.of('x' * 600));
    final props = sink.sent.single.$2;
    expect(props['length'], 'long');
    expect(props.values.any((v) => '$v'.contains('xxxx')), isFalse);
  });
}
