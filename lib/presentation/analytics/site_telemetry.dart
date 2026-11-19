import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:portfolio/data/analytics/analytics_setup.dart';
import 'package:portfolio/domain/analytics/analytics.dart';
import 'package:portfolio/domain/analytics/watchers.dart';
import 'package:portfolio/domain/models/loading_phase.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/gallery/build_timing.dart';

/// Turns what the site already knows into the plan's events: one listener
/// on the scene, one on the frames, one on the page.
///
/// Sources, per the plan: [SceneBloc] state for scenes and for the title
/// the logo accepting the tap (`$pageview`, `site_loaded`), [LoadingProgress] for how far
/// a visitor who gave up got (`load_abandoned`), [BuildTiming] for the
/// build's phases, the frame clock for `scene_health` (what `FrameWatch`
/// measures for the console, folded per scene), a main-thread watchdog for
/// `hang`, and Flutter's error hooks for `$exception`.
class SiteTelemetry {
  SiteTelemetry(this.events, {this.now = Browser.now});

  final SiteEvents events;

  /// Milliseconds since navigation started.
  final double Function() now;

  final SceneHealthMeter _health = SceneHealthMeter();
  final HangWatch _hangs = HangWatch();
  final LoadWatch _load = LoadWatch();

  LoadingPhase? _phase;
  String? _region;
  String? _piece;
  String _base = SitePath.logo;
  double? _engineReady;
  Duration? _lastFrame;
  Timer? _watchdog;
  bool _started = false;

  /// Starts watching. Called once, after the first frame, so nothing here
  /// can delay the first paint; the SDK is loaded from here for the same
  /// reason.
  void start(Analytics analytics) {
    if (_started) return;
    _started = true;
    _engineReady = now();
    startAnalytics(analytics);
    _health.begin(events.scene);

    SchedulerBinding.instance.addPersistentFrameCallback(_onFrame);

    // A stall is a timer that fires late: the main thread was busy for the
    // difference. The web's nearest thing to an ANR, and it needs nothing
    // the browser may not have.
    var last = now();
    _watchdog = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final t = now();
      final late = (t - last - 250).round();
      last = t;
      if (Browser.visible) stalled(late);
    });

    Browser.watch(onHide: hidden, onLeave: leaving);

    final previousFlutter = FlutterError.onError;
    FlutterError.onError = (details) {
      events.exception(details.exception, details.stack);
      previousFlutter?.call(details);
    };
    final previousPlatform = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      events.exception(error, stack);
      return previousPlatform?.call(error, stack) ?? false;
    };
  }

  void _onFrame(Duration stamp) {
    final previous = _lastFrame;
    _lastFrame = stamp;
    if (previous == null || !Browser.visible) return;
    frame((stamp - previous).inMicroseconds / 1000);
  }

  /// One frame took [ms]. Public for the tests.
  @visibleForTesting
  void frame(double ms) => _health.frame(ms);

  /// The main thread was held for [ms]. Public for the tests.
  @visibleForTesting
  void stalled(int ms) {
    if (!_hangs.admit(ms)) return;
    events.hang(ms: ms, during: _during());
  }

  String _during() {
    if (!BuildTiming.done && _base != SitePath.gallery) return 'gallery_build';
    if (_piece != null) return 'focus';
    if (_base == SitePath.gallery) return _region == null ? 'walk' : 'hall';
    return _base.replaceFirst('/#/', '');
  }

  /// The scene changed. The one listener on [SceneBloc].
  void onScene(SceneState state) {
    if (state is Loading) {
      _phase = state.progress.furthest ?? _phase;
      return;
    }
    final base = switch (state) {
      Logo() || LogoOverlayRemoving() => SitePath.logo,
      TitleLoading() || Title() || Active() => SitePath.title,
      Gallery() => SitePath.gallery,
      Contact() => SitePath.contact,
      Loading() => _base,
    };
    if (base != SitePath.gallery) {
      _piece = null;
      _region = null;
    }
    _base = base;
    _enter();

    // Loading has ended when the logo first accepts the tap: the gate
    // lifting. Not the title taking input, which waits on the visitor's
    // tap and so measured their patience; that wait is the gap between the
    // /#/logo and /#/title page views.
    if (state is Logo && state.isInteractive && _load.arrive()) {
      events.siteLoaded(_timings());
    }
  }

  /// A piece was focused in the gallery, or let go (null).
  void onPiece(String? projectId) {
    _piece = projectId;
    _enter();
  }

  /// The visitor reached the testimonial wall or the skills hall, or left
  /// them (null).
  void onRegion(String? path) {
    if (path == _region) return;
    _region = path;
    _enter();
  }

  void _enter() {
    final path = _base != SitePath.gallery
        ? _base
        : _piece != null
        ? SitePath.piece(_piece!)
        : _region ?? SitePath.gallery;
    // The same scene again is no new view; the first one always is.
    if (path == events.scene && events.entered) return;
    // Where the visitor is, on the page's timeline (tool/check_journey.py).
    Browser.mark('scene:$path');
    final summary = _health.take();
    if (summary != null) events.sceneHealth(summary);
    if (events.enter(path)) _health.begin(path);
  }

  /// The page was hidden: the visit to this scene is over as far as frames
  /// go. Sent by beacon, because the tab may never come back.
  @visibleForTesting
  void hidden() {
    final summary = _health.take();
    if (summary != null) events.sceneHealth(summary, closing: true);
  }

  /// The page is being closed. Before the title took input, that is a
  /// visitor who gave up waiting.
  @visibleForTesting
  void leaving() {
    hidden();
    if (!_load.leave()) return;
    events.loadAbandoned(<String, Object?>{
      'phase_reached': _phase?.name ?? 'none',
      'ms_waited': now().round(),
      ..._device(),
    });
  }

  Map<String, Object?> _device() => <String, Object?>{
    'cores': Browser.cores(),
    'memory_gb': Browser.memoryGb(),
    'connection': Browser.connection(),
  }..removeWhere((_, v) => v == null);

  Map<String, Object?> _timings() => <String, Object?>{
    'ms_first_paint': Browser.firstPaint()?.round(),
    'ms_engine_ready': _engineReady?.round(),
    'ms_gallery_built': BuildTiming.finishedAt?.round(),
    'ms_ready': now().round(),
    if (BuildTiming.done) 'build_phases': BuildTiming.phases,
    'renderer': Browser.renderer(),
    ..._device(),
  }..removeWhere((_, v) => v == null);

  void dispose() => _watchdog?.cancel();
}
