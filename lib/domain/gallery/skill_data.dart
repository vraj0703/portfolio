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
  });

  final String id;

  /// Printed on the keycap. Abbreviated where the full name would not fit.
  final String label;

  final SkillCategory category;

  /// Accent colour for the keycap's legend and its underglow contribution.
  final Color color;
}

abstract final class GallerySkills {
  /// Row 0 (top) → row 3 (bottom), matching the keyboard's near-to-far order.
  static const List<List<Skill>> rows = <List<Skill>>[
    // Row 0 — Languages
    <Skill>[
      Skill(id: 'dart', label: 'Dart', category: SkillCategory.language, color: Color(0xFF0175C2)),
      Skill(id: 'typescript', label: 'TS', category: SkillCategory.language, color: Color(0xFF3178C6)),
      Skill(id: 'javascript', label: 'JS', category: SkillCategory.language, color: Color(0xFFF7DF1E)),
      Skill(id: 'python', label: 'Py', category: SkillCategory.language, color: Color(0xFF3776AB)),
      Skill(id: 'glsl', label: 'GLSL', category: SkillCategory.language, color: Color(0xFF5586A4)),
      Skill(id: 'sql', label: 'SQL', category: SkillCategory.language, color: Color(0xFF336791)),
      Skill(id: 'html', label: 'HTML', category: SkillCategory.language, color: Color(0xFFE34F26)),
      Skill(id: 'css', label: 'CSS', category: SkillCategory.language, color: Color(0xFF1572B6)),
    ],
    // Row 1 — Frameworks
    <Skill>[
      Skill(id: 'flutter', label: 'Flutter', category: SkillCategory.framework, color: Color(0xFF02569B)),
      Skill(id: 'react', label: 'React', category: SkillCategory.framework, color: Color(0xFF61DAFB)),
      Skill(id: 'threejs', label: 'Three', category: SkillCategory.framework, color: Color(0xFF049EF4)),
      Skill(id: 'nodejs', label: 'Node', category: SkillCategory.framework, color: Color(0xFF339933)),
      Skill(id: 'gsap', label: 'GSAP', category: SkillCategory.framework, color: Color(0xFF88CE02)),
      Skill(id: 'tailwind', label: 'TW', category: SkillCategory.framework, color: Color(0xFF06B6D4)),
      Skill(id: 'vite', label: 'Vite', category: SkillCategory.framework, color: Color(0xFF646CFF)),
    ],
    // Row 2 — Tools
    <Skill>[
      Skill(id: 'git', label: 'Git', category: SkillCategory.tool, color: Color(0xFFF05032)),
      Skill(id: 'docker', label: 'Docker', category: SkillCategory.tool, color: Color(0xFF2496ED)),
      Skill(id: 'postgres', label: 'PG', category: SkillCategory.tool, color: Color(0xFF4169E1)),
      Skill(id: 'firebase', label: 'Fire', category: SkillCategory.tool, color: Color(0xFFFFCA28)),
      Skill(id: 'linux', label: 'Linux', category: SkillCategory.tool, color: Color(0xFFFCC624)),
      Skill(id: 'figma', label: 'Figma', category: SkillCategory.tool, color: Color(0xFFF24E1E)),
    ],
    // Row 3 — Platforms & AI
    <Skill>[
      Skill(id: 'claude', label: 'Claude', category: SkillCategory.ai, color: Color(0xFFD4A45C)),
      Skill(id: 'ollama', label: 'Ollama', category: SkillCategory.ai, color: Color(0xFFFFFFFF)),
      Skill(id: 'tailscale', label: 'Tail', category: SkillCategory.platform, color: Color(0xFF242424)),
      Skill(id: 'cloudflare', label: 'CF', category: SkillCategory.platform, color: Color(0xFFF38020)),
      Skill(id: 'rpi', label: 'RPi', category: SkillCategory.platform, color: Color(0xFFA22846)),
    ],
  ];

  /// Flat keycap list, in row-major order — the order the boot-up sweep
  /// animation lights them in.
  static final List<Skill> all =
      rows.expand((row) => row).toList(growable: false);
}
