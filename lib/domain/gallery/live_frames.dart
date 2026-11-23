/// Frames that open their live site when focused (PORTFOLIO-6, layer 2).
///
/// In the corridor a frame shows its captured picture (`FrameCaptures`).
/// When the visitor focuses it and the camera has arrived square to it, the
/// real site is laid over the picture in an iframe, so they can scroll and
/// click it; it fades in once loaded and is removed the moment focus ends.
/// A site has to allow being framed from this origin (shunya.systems sends
/// X-Frame-Options: SAMEORIGIN until its frame-ancestors change ships).
abstract final class LiveFrames {
  /// Each frame's live page, in corridor order. Both are pages of
  /// shunya.systems: the first page, and tantr's (PORTFOLIO-6, the second
  /// frame). tool/capture_frame.py declares the same URLs.
  static const Map<String, String> _sites = <String, String>{
    'shunya-systems': 'https://shunya.systems',
    'tantr': 'https://shunya.systems/tantr/',
  };

  /// The sites that allow framing at all today. A site that refuses
  /// (X-Frame-Options, or a frame-ancestors without us) still fires the
  /// iframe's load, with the browser's "refused to connect" page in it, and
  /// a cross-origin parent cannot tell that from the real page: so it is
  /// declared here, not detected. shunya.systems allows it since
  /// vraj0703/shunya-site#9 (merged 2026-11-22), on every page.
  static const Set<String> _frameable = <String>{'shunya-systems', 'tantr'};

  /// The portfolio hosts shunya.systems' frame-ancestors names (a mirror of
  /// that header, shunya-site tools/build.py). Served from any other host
  /// (a later PR's preview, a local build) the frames keep their pictures,
  /// for the browser would show its refusal page in them.
  static const Set<String> _framedFrom = <String>{
    'https://www.vishalraj.space',
    'https://vishalraj.space',
    'https://vishal-raj-space-firebase-home--pr-28-7xiu4eqk.web.app',
  };

  /// A testing aid, never set by a visitor: `?pc-live=ORIGIN` points every
  /// live frame at its own page on ORIGIN (a local copy of the site served
  /// with a header that names the local host), from any host.
  static final String? _override = Uri.base.queryParameters['pc-live'];

  /// The live site for project [id] as this page is served, or null when
  /// its frame has none, or has one that will not be framed here (then the
  /// frame keeps its picture and the link to open the site).
  static String? urlFor(String id) =>
      urlOf(id, from: _here, override: _override);

  /// This page's origin; none off the web (a file: base has no origin).
  static final String _here =
      Uri.base.isScheme('http') || Uri.base.isScheme('https')
      ? Uri.base.origin
      : '';

  /// [urlFor] for a page served [from] an origin, with `?pc-live=`
  /// [override]: the rule itself, so a test can ask it of any host.
  static String? urlOf(String id, {required String from, String? override}) {
    final site = _sites[id];
    if (site == null) return null;
    if (override != null) {
      final to = Uri.parse(override);
      return Uri.parse(
        site,
      ).replace(scheme: to.scheme, host: to.host, port: to.port).toString();
    }
    return _frameable.contains(id) && _framedFrom.contains(from) ? site : null;
  }

  /// The frames whose live page shows here, in corridor order.
  static List<String> corridorIds({required String from, String? override}) =>
      <String>[
        for (final id in _sites.keys)
          if (urlOf(id, from: from, override: override) != null) id,
      ];

  /// [corridorIds] as this page is served.
  static List<String> get live => corridorIds(from: _here, override: _override);

  /// The site to open in its own tab from project [id]'s frame, framed or
  /// not.
  static String? siteFor(String id) => _sites[id];

  /// The page size a frame's site is laid out at, both for its capture
  /// (tool/capture_frame.py reads these two lines) and for its live iframe,
  /// which is this size scaled down to the card: so the cross-fade is the
  /// picture becoming the same page, alive, not a different layout. Exactly
  /// the card's shape, 3.56 : 2.56.
  static const int virtualWidth = 1424;
  static const int virtualHeight = 1024;

  /// The corridor's live page (the hybrid): it starts to fade in
  /// over the picture when the card covers [corridorShareFrom] of the
  /// screen, and is fully up at [corridorShareFull].
  static const double corridorShareFrom = 0.03;
  static const double corridorShareFull = 0.06;

  /// The corridor's live page does not take the gallery's light (nor does
  /// the picture, which is unlit): a touch of dimming and warmth so it sits
  /// in the room rather than glowing on it. A CSS filter.
  static const String corridorTint = 'brightness(0.88) sepia(0.10)';

  /// The camera counts as arrived when it is this close to its focus pose
  /// (world units): square to the frame, so the card is an upright rectangle
  /// on the screen and the iframe can lie exactly over it.
  static const double arrivalGap = 0.02;

  /// How long the site may take to load before the frame gives up and keeps
  /// its picture, with the link to open the site instead.
  static const Duration loadTimeout = Duration(seconds: 12);

  /// The iframe's fade over the picture once it has loaded.
  static const Duration crossFade = Duration(milliseconds: 350);
}

/// Where a frame's live site stands: a rule on the scene's state.
enum LiveFrameStatus {
  /// No live site up (nothing focused, or a frame without one).
  idle,

  /// Asked for: the iframe is loading, invisible over the picture.
  loading,

  /// Loaded and shown over the picture.
  live,

  /// It did not load (or would not be framed) in time: the picture stays.
  failed,
}

/// Which frame's live site is up, and how it stands.
class LiveFrame {
  const LiveFrame({required this.projectId, required this.status});

  static const LiveFrame none = LiveFrame(
    projectId: null,
    status: LiveFrameStatus.idle,
  );

  final String? projectId;
  final LiveFrameStatus status;

  bool get isUp =>
      status == LiveFrameStatus.loading || status == LiveFrameStatus.live;

  @override
  bool operator ==(Object other) =>
      other is LiveFrame &&
      other.projectId == projectId &&
      other.status == status;

  @override
  int get hashCode => Object.hash(projectId, status);

  @override
  String toString() => 'LiveFrame($projectId, ${status.name})';
}
