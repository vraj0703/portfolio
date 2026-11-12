import 'dart:ui';

/// Skill data, ported 1:1 from the React gallery's `src/config/skills.ts`.
///
/// The rows map directly onto the floating keyboard's physical layout in the
/// exhibition hall — one keycap per skill, one keyboard row per list. Row
/// lengths are deliberately uneven (8/7/6/5) so the board tapers like a real
/// keyboard; the mesh builder centres each row independently.

enum SkillCategory { language, framework, tool, platform, ai }

class Skill {
  const Skill({
    required this.id,
    required this.label,
    required this.category,
    required this.color,
    this._name,
  });

  final String id;

  /// Printed on the keycap. Abbreviated where the full name would not fit.
  final String label;

  /// The skill's full name, for the caption under the board. Defaults to
  /// [label]; given only where the label is shortened to fit a key.
  String get name => _name ?? label;
  final String? _name;

  final SkillCategory category;

  /// Accent colour for the keycap's legend and its underglow contribution.
  final Color color;
}

abstract final class GallerySkills {
  /// Row 0 (top) → row 3 (bottom), matching the keyboard's near-to-far order.
  static const List<List<Skill>> rows = <List<Skill>>[
    // Row 0 — the languages, and the tool every one of them lives in
    <Skill>[
      Skill(
        id: 'dart',
        label: 'Dart',
        category: SkillCategory.language,
        color: Color(0xFF0175C2),
      ),
      Skill(
        id: 'kotlin',
        label: 'Kotlin',
        category: SkillCategory.language,
        color: Color(0xFF7F52FF),
      ),
      Skill(
        id: 'python',
        label: 'Python',
        category: SkillCategory.language,
        color: Color(0xFF3776AB),
      ),
      Skill(
        id: 'typescript',
        label: 'TS',
        name: 'TypeScript',
        category: SkillCategory.language,
        color: Color(0xFF3178C6),
      ),
      Skill(
        id: 'sql',
        label: 'SQL',
        category: SkillCategory.language,
        color: Color(0xFF336791),
      ),
      Skill(
        id: 'glsl',
        label: 'GLSL',
        category: SkillCategory.language,
        color: Color(0xFF5586A4),
      ),
      Skill(
        id: 'bash',
        label: 'Bash',
        category: SkillCategory.language,
        color: Color(0xFF4EAA25),
      ),
      Skill(
        id: 'git',
        label: 'Git',
        category: SkillCategory.tool,
        color: Color(0xFFF05032),
      ),
    ],
    // Row 1 — frameworks
    <Skill>[
      Skill(
        id: 'flutter',
        label: 'Flutter',
        category: SkillCategory.framework,
        color: Color(0xFF02569B),
      ),
      Skill(
        id: 'flame',
        label: 'Flame',
        category: SkillCategory.framework,
        color: Color(0xFFFF7A1A),
      ),
      Skill(
        id: 'bloc',
        label: 'BLoC',
        category: SkillCategory.framework,
        color: Color(0xFF8A5CF5),
      ),
      Skill(
        id: 'compose',
        label: 'Compose',
        name: 'Jetpack Compose',
        category: SkillCategory.framework,
        color: Color(0xFF4285F4),
      ),
      Skill(
        id: 'flutter_scene',
        label: 'Scene',
        name: 'flutter_scene',
        category: SkillCategory.framework,
        color: Color(0xFF13B9FD),
      ),
      Skill(
        id: 'shelf',
        label: 'Shelf',
        category: SkillCategory.framework,
        color: Color(0xFF00B4AB),
      ),
      Skill(
        id: 'react',
        label: 'React',
        category: SkillCategory.framework,
        color: Color(0xFF61DAFB),
      ),
    ],
    // Row 2 — where it runs
    <Skill>[
      Skill(
        id: 'docker',
        label: 'Docker',
        category: SkillCategory.tool,
        color: Color(0xFF2496ED),
      ),
      Skill(
        id: 'firebase',
        label: 'Fire',
        name: 'Firebase',
        category: SkillCategory.platform,
        color: Color(0xFFFFCA28),
      ),
      Skill(
        id: 'gcp',
        label: 'GCP',
        name: 'Google Cloud',
        category: SkillCategory.platform,
        color: Color(0xFF4285F4),
      ),
      Skill(
        id: 'cloudflare',
        label: 'CF',
        name: 'Cloudflare',
        category: SkillCategory.platform,
        color: Color(0xFFF38020),
      ),
      Skill(
        id: 'tailscale',
        label: 'Tail',
        name: 'Tailscale',
        category: SkillCategory.platform,
        color: Color(0xFF4A4A4A),
      ),
      Skill(
        id: 'posthog',
        label: 'PostHog',
        category: SkillCategory.tool,
        color: Color(0xFFF54E00),
      ),
    ],
    // Row 3 — the AI it is built with, and how it ships
    <Skill>[
      Skill(
        id: 'claude_code',
        label: 'Claude',
        name: 'Claude Code',
        category: SkillCategory.ai,
        color: Color(0xFFD4A45C),
      ),
      Skill(
        id: 'mcp',
        label: 'MCP',
        name: 'Model Context Protocol',
        category: SkillCategory.ai,
        color: Color(0xFFB0B0B0),
      ),
      Skill(
        id: 'ollama',
        label: 'Ollama',
        category: SkillCategory.ai,
        color: Color(0xFFFFFFFF),
      ),
      Skill(
        id: 'rag',
        label: 'RAG',
        name: 'Retrieval-augmented generation',
        category: SkillCategory.ai,
        color: Color(0xFF9C6ADE),
      ),
      Skill(
        id: 'github_actions',
        label: 'CI',
        name: 'GitHub Actions',
        category: SkillCategory.tool,
        color: Color(0xFF2088FF),
      ),
    ],
  ];

  static final List<Skill> all = rows
      .expand((row) => row)
      .toList(growable: false);
}
