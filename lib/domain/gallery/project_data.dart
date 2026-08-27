import 'dart:ui';

/// Portfolio project data, ported 1:1 from the React gallery's
/// `src/config/projects.ts`.
///
/// Ordering is load-bearing. [GalleryProjects.left] and
/// [GalleryProjects.right] index into [GalleryProjects.all] to build the
/// paired corridor layout, and the corridor's physical length is derived
/// from the left-wall count in `gallery_dimensions.dart`. Reordering this
/// list moves walls.

/// Selects which generative artwork is drawn onto a project's frame canvas.
///
/// Each value maps to a painter in `gallery/textures/project_artwork.dart`.
enum ProjectVisual { mesh, pipeline, timeline, graph, funnel, dashboard, chat }

class Project {
  const Project({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.gradient,
    required this.stats,
    required this.visual,
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
    ),
    Project(
      id: 'ai-mind',
      title: 'ai-mind',
      description: 'Cognitive Orchestration Organ',
      url: 'https://github.com/vraj0703/ai-mind',
      gradient: (Color(0xFF4338CA), Color(0xFF1E1B4B)),
      stats: <String>['Decision Routing', '3-Tier LLM', 'Clean Architecture'],
      visual: ProjectVisual.pipeline,
    ),
    Project(
      id: 'ai-constitution',
      title: 'ai-constitution',
      description: 'Trust Layer for Autonomous Agents',
      url: 'https://github.com/vraj0703/ai-constitution',
      gradient: (Color(0xFF10B981), Color(0xFF064E3B)),
      stats: <String>['Governance', 'Autonomy Limits', 'Audit Trails'],
      visual: ProjectVisual.timeline,
    ),
    Project(
      id: 'ai-knowledge',
      title: 'ai-knowledge',
      description: 'Self-Learning Tool Registry',
      url: 'https://github.com/vraj0703/ai-knowledge',
      gradient: (Color(0xFFF59E0B), Color(0xFF78350F)),
      stats: <String>['71 Capabilities', 'Hebbian Graph', 'Semantic Search'],
      visual: ProjectVisual.graph,
    ),
    Project(
      id: 'subwise',
      title: 'SubWise',
      description: 'Subscription Tracker',
      url: 'https://github.com/vraj0703/subwise',
      gradient: (Color(0xFFC8A45C), Color(0xFF5C3A1E)),
      stats: <String>['Kotlin 2', 'Compose', 'Material 3'],
      visual: ProjectVisual.dashboard,
    ),
    Project(
      id: 'jotter',
      title: 'Jotter',
      description: 'Notes App with In-App Purchases',
      url: 'https://github.com/vraj0703/jotter',
      gradient: (Color(0xFFEF4444), Color(0xFF7F1D1D)),
      stats: <String>['Flutter', 'RevenueCat', 'Play Store'],
      visual: ProjectVisual.chat,
    ),
    Project(
      id: 'twin-health',
      title: 'Twin Health',
      description: 'Digital Health Platform',
      url: '#',
      gradient: (Color(0xFF6366F1), Color(0xFF312E81)),
      stats: <String>['67 Releases', '0 Hotfixes', r'$87K Saved'],
      visual: ProjectVisual.funnel,
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
