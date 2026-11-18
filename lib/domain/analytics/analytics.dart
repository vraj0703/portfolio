import 'package:flutter/foundation.dart';

/// Where the site's measurements go (docs/analytics/README.md).
///
/// One interface, three verbs. Event names are not written at call sites:
/// [SiteEvents] holds every one, typed, so the plan's fifteen events exist
/// in one place and a sixteenth cannot appear by accident.
abstract class Analytics {
  /// Sends [event] with [properties]. [beforeUnload] sends it the way a page
  /// that is closing can still send: by beacon, at once.
  void capture(
    String event,
    Map<String, Object?> properties, {
    bool beforeUnload = false,
  });

  /// One `$pageview` for a scene, at [path] (`/#/gallery`, …).
  void screen(String path, Map<String, Object?> properties);

  /// Whether the flag [key] is on, or [orElse] when the flag is absent or
  /// not known yet. Never waits.
  bool flag(String key, {required bool orElse});

  /// Ticks when the flags arrive or change, so a widget showing one can
  /// redraw. Before then, every flag is its compiled default.
  Listenable get flagsChanged;

  /// An uncaught error, with its stack.
  void captureException(Object error, StackTrace? stack);
}

/// The analytics of a build with no token: nothing is sent, nothing is
/// loaded, every flag is its default.
class SilentAnalytics implements Analytics {
  SilentAnalytics();

  final ChangeNotifier _never = ChangeNotifier();

  @override
  void capture(
    String event,
    Map<String, Object?> properties, {
    bool beforeUnload = false,
  }) {}

  @override
  void screen(String path, Map<String, Object?> properties) {}

  @override
  bool flag(String key, {required bool orElse}) => orElse;

  @override
  Listenable get flagsChanged => _never;

  @override
  void captureException(Object error, StackTrace? stack) {}
}

/// What kind of screen the visitor is on, from its size.
enum DeviceClass {
  phone,
  tablet,
  desktop;

  /// By the shorter side, so a phone on its side is still a phone.
  static DeviceClass of(double width, double height) {
    final short = width < height ? width : height;
    if (short < 600) return DeviceClass.phone;
    if (short < 1024) return DeviceClass.tablet;
    return DeviceClass.desktop;
  }
}

/// How long a copied testimonial was, bucketed: never the text.
enum TextLength {
  short,
  medium,
  long;

  static TextLength of(String text) {
    final n = text.trim().length;
    if (n < 140) return TextLength.short;
    if (n < 500) return TextLength.medium;
    return TextLength.long;
  }
}

/// Whether the browser has asked not to be tracked (Do Not Track, or the
/// Global Privacy Control signal). Either one, and the site loads no
/// analytics at all: nothing is stored and nothing is sent.
abstract final class PrivacySignals {
  static bool decline({String? doNotTrack, bool? globalPrivacyControl}) =>
      doNotTrack == '1' || doNotTrack == 'yes' || globalPrivacyControl == true;
}

/// How many times this browser has opened the site, kept in localStorage
/// beside PostHog's anonymous id and sent on every event as `visit_number`
/// (Vishal's decision, 2026-11-16: return visits are worth seeing).
abstract final class VisitCounter {
  /// The storage key, beside PostHog's own.
  static const String key = 'portfolio_visit_number';

  /// This visit's number, from what was stored (null or unreadable on a
  /// first visit).
  static int next(String? stored) {
    final previous = int.tryParse(stored ?? '') ?? 0;
    return previous < 0 ? 1 : previous + 1;
  }
}

/// The scenes, as the paths PostHog's own tools read (question 3).
abstract final class SitePath {
  static const String logo = '/#/logo';
  static const String title = '/#/title';
  static const String gallery = '/#/gallery';
  static const String testimonials = '/#/testimonials';
  static const String skills = '/#/skills';
  static const String contact = '/#/contact';

  /// A focused piece.
  static String piece(String projectId) => '$gallery/$projectId';
}

/// Every event the site sends, typed, and the only place their names are
/// written.
///
/// Each carries the scene, the viewport, the device class; see [_common].
/// Whether this browser has been here before rides on every event too, as
/// `visit_number`, registered with PostHog when it starts ([VisitCounter]).
/// The name is PostHog's super property, not an event, so it is not here.
class SiteEvents {
  SiteEvents(this._sink, {required this.viewport});

  final Analytics _sink;

  /// The viewport now, in logical pixels.
  final (double, double) Function() viewport;

  String _scene = SitePath.logo;

  /// The scene the visitor is in, as a path.
  String get scene => _scene;

  /// The plan's events (docs/analytics/README.md), and `sound_toggled`, one
  /// of its "two controls".
  /// PostHog's own name for a page view, which [Analytics.screen] sends.
  static const String pageview = r'$pageview';

  static const Set<String> names = <String>{
    'site_loaded',
    'load_abandoned',
    'scene_health',
    'hang',
    r'$exception',
    r'$pageview',
    'cv_opened',
    'contact_link_clicked',
    'project_case_opened',
    'project_link_opened',
    'publication_opened',
    'testimonial_form_opened',
    'testimonial_text_copied',
    'testimonial_linkedin_opened',
    'testimonial_submitted',
    'sound_toggled',
    'menu_opened',
    'radio_toggled',
    'radio_station_changed',
    'nav_selected',
  };

  Map<String, Object?> _common() {
    final (w, h) = viewport();
    return <String, Object?>{
      'scene': _scene,
      'viewport': '${w.round()}x${h.round()}',
      'device_class': DeviceClass.of(w, h).name,
    };
  }

  void _send(String name, Map<String, Object?> props, {bool beacon = false}) {
    assert(names.contains(name), name);
    _sink.capture(name, <String, Object?>{
      ..._common(),
      ...props,
    }, beforeUnload: beacon);
  }

  /// Question 3: the visitor is now in [path]. Sends one `$pageview` per
  /// change; the same scene twice is one view.
  bool enter(String path) {
    if (path == _scene && _entered) return false;
    _entered = true;
    _scene = path;
    _sink.screen(path, _common());
    return true;
  }

  bool _entered = false;

  /// Whether any scene has been announced yet.
  bool get entered => _entered;

  // Question 1.
  void siteLoaded(Map<String, Object?> timings) =>
      _send('site_loaded', timings);
  void loadAbandoned(Map<String, Object?> props) =>
      _send('load_abandoned', props, beacon: true);

  // Question 2.
  void sceneHealth(Map<String, Object?> summary, {bool closing = false}) =>
      _send('scene_health', summary, beacon: closing);
  void hang({required int ms, required String during}) =>
      _send('hang', <String, Object?>{'ms': ms, 'during': during});
  void exception(Object error, StackTrace? stack) =>
      _sink.captureException(error, stack);

  // Question 4.
  void cvOpened() => _send('cv_opened', <String, Object?>{'from': _scene});
  void contactLinkClicked(String channel) => _send(
    'contact_link_clicked',
    <String, Object?>{'channel': channel, 'from': _scene},
  );
  void projectCaseOpened(String project) =>
      _send('project_case_opened', <String, Object?>{'project': project});
  void projectLinkOpened(String project, String host) => _send(
    'project_link_opened',
    <String, Object?>{'project': project, 'host': host},
  );
  void publicationOpened(String registry, String name) => _send(
    'publication_opened',
    <String, Object?>{'registry': registry, 'name': name},
  );

  // Question 5.
  void testimonialFormOpened() =>
      _send('testimonial_form_opened', const <String, Object?>{});
  void testimonialTextCopied(TextLength length) => _send(
    'testimonial_text_copied',
    <String, Object?>{'length': length.name},
  );
  void testimonialLinkedinOpened() =>
      _send('testimonial_linkedin_opened', const <String, Object?>{});

  /// Reserved for the day submitting happens on the site; nothing calls it
  /// yet.
  void testimonialSubmitted() =>
      _send('testimonial_submitted', const <String, Object?>{});

  // The two controls.
  void soundToggled({required bool muted}) =>
      _send('sound_toggled', <String, Object?>{'muted': muted});

  // The menu and the radio (PORTFOLIO-23).
  void menuOpened() => _send('menu_opened', <String, Object?>{'scene': _scene});

  /// The radio put on ([on]) or off, from [surface]: `drawer` or `wall`.
  void radioToggled({required bool on, required String surface}) =>
      _send('radio_toggled', <String, Object?>{'on': on, 'surface': surface});

  /// The radio stepped to [station], from [surface]: `drawer` or `wall`.
  void radioStationChanged({
    required String station,
    required String surface,
  }) => _send('radio_station_changed', <String, Object?>{
    'station': station,
    'surface': surface,
  });

  /// The drawer's bar (PORTFOLIO-24): where to, from which scene, and
  /// whether it was where the visitor already was (a tap that only closes).
  void navSelected({
    required String destination,
    required bool alreadyCurrent,
  }) => _send('nav_selected', <String, Object?>{
    'destination': destination,
    'from_scene': _scene,
    'already_current': alreadyCurrent,
  });

  // Flags. `title_connect_button` is gone with the title's heart
  // (PORTFOLIO-23); the contact page is reached from the drawer's bar.
  static const String menuFlag = 'title_menu_button';
  static const String walkStickFlag = 'gallery_walk_stick';

  bool showsMenu() => _sink.flag(menuFlag, orElse: true);
  bool walksByStick() => _sink.flag(walkStickFlag, orElse: true);
  Listenable get flagsChanged => _sink.flagsChanged;
}
