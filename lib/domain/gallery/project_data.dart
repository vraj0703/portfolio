import 'dart:ui';

/// Portfolio project data, ported 1:1 from the React gallery's
/// `src/config/projects.ts`.
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
    Project(
      id: 'raj-sadan',
      title: 'Raj Sadan',
      description: 'Multi-Agent AI Governance System',
      url: 'https://github.com/vraj0703',
      gradient: (Color(0xFFD4A800), Color(0xFF5C3A1E)),
      stats: <String>['11 Public Repos', '474 Tests', '4-Layer Governance'],
      visual: ProjectVisual.mesh,
      summary:
          'An operating system for a team of AI agents. Four layers of '
          'governance decide what an agent may do on its own, what it must '
          'ask about, and what it must never touch.',
      stack: <String>['TypeScript', 'Node', 'TOML', 'MCP'],
    ),
    Project(
      id: 'ai-mind',
      title: 'ai-mind',
      description: 'Cognitive Orchestration Organ',
      url: 'https://github.com/vraj0703/ai-mind',
      gradient: (Color(0xFF4338CA), Color(0xFF1E1B4B)),
      stats: <String>['Decision Routing', '3-Tier LLM', 'Clean Architecture'],
      visual: ProjectVisual.pipeline,
      summary:
          'The part that decides which model answers. Routes each request by '
          'what it actually needs, so the expensive tier is spent on the work '
          'that warrants it and not on everything.',
      stack: <String>['Clean Architecture', 'Multi-model'],
    ),
    Project(
      id: 'ai-constitution',
      title: 'ai-constitution',
      description: 'Trust Layer for Autonomous Agents',
      url: 'https://github.com/vraj0703/ai-constitution',
      gradient: (Color(0xFF10B981), Color(0xFF064E3B)),
      stats: <String>['Governance', 'Autonomy Limits', 'Audit Trails'],
      visual: ProjectVisual.timeline,
      summary:
          'Rules an autonomous agent cannot talk its way out of. Limits are '
          'declared outside the agent and every decision leaves a trail, so '
          'what it did is answerable after the fact.',
      stack: <String>['TOML', 'Policy engine', 'Audit log'],
    ),
    Project(
      id: 'ai-knowledge',
      title: 'ai-knowledge',
      description: 'Self-Learning Tool Registry',
      url: 'https://github.com/vraj0703/ai-knowledge',
      gradient: (Color(0xFFF59E0B), Color(0xFF78350F)),
      stats: <String>['71 Capabilities', 'Hebbian Graph', 'Semantic Search'],
      visual: ProjectVisual.graph,
      status: ProjectStatus.soon,
    ),
    Project(
      id: 'subwise',
      title: 'SubWise',
      description: 'Subscription Tracker',
      url: 'https://github.com/vraj0703/subwise',
      gradient: (Color(0xFFC8A45C), Color(0xFF5C3A1E)),
      stats: <String>['Kotlin 2', 'Compose', 'Material 3'],
      visual: ProjectVisual.dashboard,
      status: ProjectStatus.soon,
    ),
    Project(
      id: 'jotter',
      title: 'Jotter',
      description: 'Notes App with In-App Purchases',
      url: 'https://github.com/vraj0703/jotter',
      gradient: (Color(0xFFEF4444), Color(0xFF7F1D1D)),
      stats: <String>['Flutter', 'RevenueCat', 'Play Store'],
      visual: ProjectVisual.chat,
      status: ProjectStatus.soon,
    ),
    Project(
      id: 'twin-health',
      title: 'Twin Health',
      description: 'Digital Health Platform',
      url: '#',
      gradient: (Color(0xFF6366F1), Color(0xFF312E81)),
      stats: <String>['67 Releases', '0 Hotfixes', r'$87K Saved'],
      visual: ProjectVisual.funnel,
      status: ProjectStatus.soon,
    ),
  ];

  /// Left wall: indices 0, 2, 4, 6. Takes the extra project — P7 hangs alone
  /// past the point where the right wall stops and opens into the L.
  static final List<Project> left = <Project>[
    all[0],
    all[2],
    all[4],
    all[6],
  ];

  /// Right wall: indices 1, 3, 5. Each faces its left-wall pair.
  static final List<Project> right = <Project>[
    all[1],
    all[3],
    all[5],
  ];
}
