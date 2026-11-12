import 'dart:ui';

/// The corridor's seven frames. The left wall is what Vishal builds now; the
/// right wall is where he built before.
///
/// Every number and claim here can be checked: Shunya Systems against the
/// mantr, yantr and infra repositories, tantr against the tantr-app
/// repository and https://tantr.app, Twin Health and FieldAssist / PayU
/// against the entries this list replaced and the old static page. Anything
/// not yet backed by a fact is left out of what renders and marked with a
/// `TODO(vishal)` comment beside it. A TODO marker never reaches the wall or
/// the static page; the frames still waiting on facts are `soon`, which show
/// their title and nothing they cannot back.
///
/// Ordering is load-bearing. [GalleryProjects.left] and
/// [GalleryProjects.right] index into [GalleryProjects.all] to build the
/// paired corridor layout, and the corridor's physical length is derived
/// from the left-wall count in `gallery_dimensions.dart`. Reordering this
/// list moves walls.

/// Which generative artwork a project's card would carry.
///
/// Kept while the cards are deliberately blank: the painters that consumed it
/// were deleted with them, and the choice per project is content worth
/// keeping rather than something to re-decide when the cards are filled in.
enum ProjectVisual { mesh, pipeline, timeline, graph, funnel, dashboard, chat }

/// How far along a piece of work is.
///
/// A gallery does not hang an empty frame where a work is not ready — it
/// hangs the frame and says so on the card. Unfinished work stays on the wall
/// because the shape of what is coming is itself worth seeing; it is simply
/// not lit the same way. See `GalleryLighting`, where [ProjectStatus.soon]
/// gets a dimmer picture light: the room states the difference before any
/// text does.
enum ProjectStatus {
  /// Finished, public, and worth reading in full.
  live,

  /// Announced, not yet ready. Shows its premise and nothing it cannot back.
  soon,
}

class Project {
  const Project({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.gradient,
    required this.stats,
    required this.visual,
    this.status = ProjectStatus.live,
    this.summary = '',
    this.stack = const <String>[],
  });

  final String id;
  final String title;
  final String description;
  final String url;

  /// Two-stop linear gradient painted as the artwork's base layer.
  final (Color, Color) gradient;

  /// Key metrics printed along the bottom of the frame.
  final List<String> stats;

  final ProjectVisual visual;

  final ProjectStatus status;

  /// What the work is for, in the visitor's terms rather than the author's.
  ///
  /// The one thing [description] cannot carry: it is a label, read in passing
  /// at four metres, and has to stay short enough to be. This is read at
  /// arm's length by someone who has already stopped, and answers the
  /// question a label cannot — *why does this exist*.
  final String summary;

  /// What it is built with. Named, not counted: a stack is how a reader
  /// decides whether they recognise the work, and a number tells them
  /// nothing.
  final List<String> stack;

  /// Whether there is a finished case to read, as opposed to a premise.
  bool get isLive => status == ProjectStatus.live;

  /// Projects with no public link render without a clickable affordance.
  bool get hasLink => url.isNotEmpty && url != '#';
}

abstract final class GalleryProjects {
  static const List<Project> all = <Project>[
    // 0 · left 1 — what he builds now.
    Project(
      id: 'shunya-systems',
      title: 'Shunya Systems',
      description: 'A Two-Person Company Run with AI Agents',
      // TODO(vishal): the repositories are private; link a public page here
      // or leave it without one.
      url: '#',
      gradient: (Color(0xFFD4A800), Color(0xFF5C3A1E)),
      stats: <String>['5 Nodes', '22 Written Rules', '15 Instruments'],
      visual: ProjectVisual.mesh,
      summary:
          'A company of two, Vishal and an AI chief of staff. The agent '
          'plans and reviews on one machine and hands the work to agents on '
          'the others, under 22 written rules that say what it may do alone, '
          'what it must ask about, and what it must never touch.',
      stack: <String>['Claude Code', 'Python', 'Salt', 'Tailscale'],
    ),
    // 1 · right 1 — where he built before.
    Project(
      id: 'twin-health',
      title: 'Twin Health',
      description: 'Digital Health Platform',
      url: '#',
      gradient: (Color(0xFF6366F1), Color(0xFF312E81)),
      stats: <String>['67 Releases', '0 Hotfixes', r'$87K Saved'],
      visual: ProjectVisual.funnel,
      summary:
          'A digital health platform, from 2022: 67 releases shipped '
          'without a single hotfix.',
      // TODO(vishal): the role, what the $87K saving was, and the stack.
      stack: <String>[],
    ),
    // 2 · left 2
    Project(
      id: 'tantr',
      title: 'tantr app',
      description: 'One Runtime for the Five Things Every App Rebuilds',
      url: 'https://tantr.app',
      gradient: (Color(0xFF10B981), Color(0xFF064E3B)),
      stats: <String>['31 Packages', '5 Profiles', '7 Apps'],
      visual: ProjectVisual.pipeline,
      summary:
          'Most product apps rebuild the same five things: forms, insight '
          'cards, notifications, asking the user to act, and chat. tantr '
          'writes them once behind one wire contract, and a new product is '
          'carved from a reference app in one command.',
      stack: <String>['Flutter', 'Dart', 'shelf', 'JSON Schema'],
    ),
    // 3 · right 2
    Project(
      id: 'fieldassist-payu',
      title: 'FieldAssist / PayU',
      description: 'Field Force at Scale · Payment Encryption',
      url: '#',
      gradient: (Color(0xFFC8A45C), Color(0xFF5C3A1E)),
      stats: <String>['1600+ Files', 'Multi-Flavor', 'Triple DES'],
      visual: ProjectVisual.dashboard,
      summary:
          'At PayU, in fintech from 2016: client-side encryption of card PIN '
          'and PAN with Triple DES. At FieldAssist, in FMCG from 2018: an '
          'enterprise field-force app of more than 1,600 files, shipped in '
          'several flavors.',
      // TODO(vishal): the role at each, and the stack.
      stack: <String>[],
    ),
    // 4 · left 3
    Project(
      id: 'publications',
      title: 'Publications',
      // TODO(vishal): what is published, where, and a link.
      description: '',
      url: '#',
      gradient: (Color(0xFF4338CA), Color(0xFF1E1B4B)),
      stats: <String>[],
      visual: ProjectVisual.timeline,
      status: ProjectStatus.soon,
      // TODO(vishal): two or three sentences on the writing.
    ),
    // 5 · right 3
    Project(
      id: 'school-college',
      title: 'School and College',
      // TODO(vishal): the schools, the college, the degree and the years.
      description: '',
      url: '#',
      gradient: (Color(0xFFF59E0B), Color(0xFF78350F)),
      stats: <String>[],
      visual: ProjectVisual.graph,
      status: ProjectStatus.soon,
      // TODO(vishal): two or three sentences on where it started.
    ),
    // 6 · left 4, alone past the end of the right wall
    Project(
      id: 'creative-works',
      title: 'Creative Works',
      // TODO(vishal): which works, and a link.
      description: '',
      url: '#',
      gradient: (Color(0xFFEF4444), Color(0xFF7F1D1D)),
      stats: <String>[],
      visual: ProjectVisual.chat,
      status: ProjectStatus.soon,
      // TODO(vishal): two or three sentences on the creative work.
    ),
  ];

  /// Left wall, what he builds now: indices 0, 2, 4, 6. Takes the extra
  /// frame — the last hangs alone past the point where the right wall stops
  /// and opens into the L.
  static final List<Project> left = <Project>[
    all[0],
    all[2],
    all[4],
    all[6],
  ];

  /// Right wall, where he built before: indices 1, 3, 5. Each faces its
  /// left-wall pair.
  static final List<Project> right = <Project>[
    all[1],
    all[3],
    all[5],
  ];
}
