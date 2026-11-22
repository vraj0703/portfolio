/// Frames that open their live site when focused (PORTFOLIO-6, layer 2).
///
/// In the corridor a frame shows its captured picture (`FrameCaptures`).
/// When the visitor focuses it and the camera has arrived square to it, the
/// real site is laid over the picture in an iframe, so they can scroll and
/// click it; it fades in once loaded and is removed the moment focus ends.
/// A site has to allow being framed from this origin (shunya.systems sends
/// X-Frame-Options: SAMEORIGIN until its frame-ancestors change ships).
abstract final class LiveFrames {
  static const Map<String, String> _sites = <String, String>{
    'shunya-systems': 'https://shunya.systems',
  };

  /// The sites that allow this origin to frame them today. A site that
  /// refuses (X-Frame-Options, or a frame-ancestors without us) still fires
  /// the iframe's load, with the browser's "refused to connect" page in it,
  /// and a cross-origin parent cannot tell that from the real page: so it is
  /// declared here, not detected. shunya.systems joins once its
  /// frame-ancestors change (vraj0703/shunya-site) is live.
  static const Set<String> _frameable = <String>{};

  /// A testing aid, never set by a visitor: `?pc-live=URL` points every live
  /// frame at URL (a local copy of a site served with the new header).
  static final String? _override = Uri.base.queryParameters['pc-live'];

  /// Whether a test page was named with `?pc-live` (the measuring hook).
  static bool get overridden => _override != null;

  /// The live site for project [id], or null when its frame has none, or
  /// has one that does not allow framing yet (then the frame keeps its
  /// picture and the link to open the site). `?pc-live=` overrides both.
  static String? urlFor(String id) {
    final site = _sites[id];
    if (site == null) return null;
    final override = _override;
    if (override != null) return override;
    return _frameable.contains(id) ? site : null;
  }

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

  /// The corridor's live page (prototype, the hybrid): it starts to fade in
  /// over the picture when the card covers [corridorShareFrom] of the
  /// screen, and is fully up at [corridorShareFull].
  /// `?pc-live-share=` overrides the start (a measuring hook, prototype).
  static final double corridorShareFrom =
      double.tryParse(Uri.base.queryParameters['pc-live-share'] ?? '') ?? 0.03;
  static double get corridorShareFull => corridorShareFrom + 0.03;

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
