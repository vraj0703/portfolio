import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/style/strings.dart';

void main() {
  const strings = DefaultAppStrings();

  group('the far wall\'s writing', () {
    test('is copy, not part of a texture-baking routine', () {
      // It lived inside the mesh builder, which is where the longest piece
      // of writing in the app is least likely to be found by whoever comes
      // to rewrite it.
      expect(strings.wallName, isNotEmpty);
      expect(strings.wallStatement, isNotEmpty);
    });

    test('carries no layout in it', () {
      // The gap between the name and the paragraph is a measurement passed
      // to the renderer. Written into the string as a newline it is
      // invisible to whoever edits the sentence, and the first thing they do
      // is lose it.
      for (final line in <String>[strings.wallName, strings.wallStatement]) {
        expect(line, isNot(contains('\n')));
        expect(line.trim(), line, reason: 'padded with whitespace');
      }
    });

    test('says who it is about', () {
      expect(strings.wallName, contains('VISHAL'));
    });
  });
}
