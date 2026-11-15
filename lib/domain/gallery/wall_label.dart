import 'project_data.dart';

/// One row of a wall label.
enum LabelRow { name, line, figure, tags, years }

/// What a piece's wall label says, under the label's rule.
///
/// Five things, the same on every piece: the name; one line of at most
/// [maxLineWords] words; one number; up to [maxTags] tags; and the years.
/// Anything else belongs on the sheet. A field the project does not have
/// yet is left off, not announced: an empty row on a label reads as a
/// mistake, and a placeholder reads as an unfinished site.
class WallLabel {
  const WallLabel._(this.project);

  factory WallLabel.of(Project project) => WallLabel._(project);

  final Project project;

  static const int maxLineWords = 8;
  static const int maxTags = 3;

  /// The rows this label carries, top to bottom.
  List<LabelRow> get rows => <LabelRow>[
    LabelRow.name,
    if (project.line.isNotEmpty) LabelRow.line,
    if (project.figure.isNotEmpty) LabelRow.figure,
    if (project.tags.isNotEmpty) LabelRow.tags,
    if (project.years.isNotEmpty) LabelRow.years,
  ];

  /// How many words [Project.line] runs to.
  int get lineWords =>
      project.line.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

  /// Whether the project's label fits the rule.
  bool get followsRule =>
      lineWords <= maxLineWords && project.tags.length <= maxTags;
}
