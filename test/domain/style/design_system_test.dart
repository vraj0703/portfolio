import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keeps type and colour where they are declared.
///
/// A guard rather than a review note. Every widget added to this app is one
/// `TextStyle(fontSize: 14)` away from a second, private design system, and
/// the drift is invisible until two screens disagree about what grey means —
/// at which point there is nothing to change centrally, because the values
/// are spread across the files that use them.
void main() {
  /// Where type and colour are allowed to be declared.
  const styleDirectory = 'lib/domain/style/';

  /// Files that may hold colour literals, and why each one may.
  ///
  /// Every entry is a colour that is *not* a theme choice — changing the
  /// app's palette must not change any of these, so putting them in the
  /// palette would be wrong rather than tidy.
  const colourExemptions = <String, String>{
    // Brand colours. Dart's blue is Dart's, not ours.
    'lib/domain/gallery/skill_data.dart': 'each skill draws its own identity',
    'lib/domain/gallery/project_data.dart': 'each project draws its own',

    // The room's light and its surfaces. Scene values, declared beside the
    // geometry they light and read by a builder that has no BuildContext.
    'lib/domain/gallery/gallery_lighting.dart': 'the room\'s own lamps',
    'lib/presentation/gallery/gallery_scene_builder.dart':
        'plaster and timber to fall back on when a photograph will not decode',

    // Argument defaults meaning "none" and "plain", not palette entries.
    'lib/presentation/gallery/wall_text.dart': 'transparent, and white',

    // Composes the theme, so it necessarily names the theme's own pieces.
    'lib/main.dart': 'builds the theme',
  };

  Iterable<File> dartFilesUnder(String path) => Directory(path)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.endsWith('.freezed.dart'))
      .where((f) => !f.path.endsWith('.g.dart'));

  /// Repo-relative, with forward slashes, on every platform.
  String relative(File file) =>
      file.path.replaceAll(r'\', '/').split('lib/').last;

  group('the design system is the only place type is declared', () {
    test('no widget builds a TextStyle of its own', () {
      final offenders = <String>[];

      for (final file in dartFilesUnder('lib')) {
        final path = 'lib/${relative(file)}';
        if (path.startsWith(styleDirectory)) continue;
        if (file.readAsStringSync().contains('TextStyle(')) {
          offenders.add(path);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'declare the style in $styleDirectory'
            'text_styles.dart and read it through context.typography',
      );
    });

    test('no widget reaches for Material\'s text theme', () {
      final offenders = <String>[];

      for (final file in dartFilesUnder('lib')) {
        // Material's own scale is a different design system with different
        // sizes, weights and a different font — reading from it means a
        // screen that looks nothing like the rest.
        if (file.readAsStringSync().contains('textTheme')) {
          offenders.add('lib/${relative(file)}');
        }
      }

      expect(offenders, isEmpty, reason: 'read context.typography instead');
    });
  });

  group('the design system is the only place colour is declared', () {
    test('no widget names a colour of its own', () {
      final offenders = <String>[];
      final literal = RegExp(r'Color\(0x|Colors\.[a-z]');

      for (final file in dartFilesUnder('lib')) {
        final path = 'lib/${relative(file)}';
        if (path.startsWith(styleDirectory)) continue;
        if (colourExemptions.containsKey(path)) continue;
        if (literal.hasMatch(file.readAsStringSync())) offenders.add(path);
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'declare the colour in ${styleDirectory}colors.dart and read it '
            'through context.colors — or, for a Flame component, through '
            'ScenePalette',
      );
    });

    test('every exemption still names a file that exists', () {
      // An exemption for a file that has been deleted or renamed is a hole
      // in the guard that nothing else will report.
      for (final path in colourExemptions.keys) {
        expect(File(path).existsSync(), isTrue, reason: '$path is gone');
      }
    });
  });
}
