import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/style/text_styles.dart';

/// Every family the app sets type in, and the file behind it.
///
/// Written out rather than parsed from the pubspec on purpose: parsing it
/// would only prove the pubspec agrees with itself. This is the other side of
/// the contract — what the styles ask for — and the test is that the two
/// meet.
const declared = <String, String>{
  'MonoLoading': 'fonts/mono_loading.ttf',
  'AzeretMono': 'fonts/azeretmono.ttf',
  'Apertura': 'fonts/aperturaregular.ttf',
  'ModrntUrban': 'fonts/modrnt_urban.otf',
  'Marcellus': 'fonts/marcellus.ttf',
  'Margot': 'fonts/Margot-Regular.ttf',
};

void main() {
  const type = DefaultAppTypography();

  /// Every style the app sets, by the name it is asked for.
  final styles = <String, String?>{
    'loading': type.loading.fontFamily,
    'loadingReadout': type.loadingReadout.fontFamily,
    'enter': type.enter.fontFamily,
    'titlePrimary': type.titlePrimary.fontFamily,
    'titleSecondary': type.titleSecondary.fontFamily,
    'boldText': type.boldText.fontFamily,
    'wallName': type.wallName.fontFamily,
    'wallStatement': type.wallStatement.fontFamily,
    'wallSign': type.wallSign.fontFamily,
    'galleryControl': type.galleryControl.fontFamily,
    'galleryFailure': type.galleryFailure.fontFamily,
    'contactMenu': type.contactMenu.fontFamily,
    'creditsTitle': type.creditsTitle.fontFamily,
    'creditsSubtitle': type.creditsSubtitle.fontFamily,
    'creditsHeading': type.creditsHeading.fontFamily,
    'creditsBody': type.creditsBody.fontFamily,
    'creditsAction': type.creditsAction.fontFamily,
  };

  group('every face a style asks for', () {
    test('is one the app declares', () {
      // The failure this catches is silent. A family Flutter cannot resolve
      // is not an error — it falls back to the platform's default and
      // renders perfectly happily, so a typo in a family name looks like a
      // design choice until somebody who knows the typeface sees it.
      for (final entry in styles.entries) {
        final family = entry.value;
        if (family == null) continue;

        expect(
          declared.keys,
          contains(family),
          reason: '${entry.key} is set in $family, which is not declared',
        );
      }
    });

    test('and has a file behind it that is actually there', () {
      for (final entry in declared.entries) {
        expect(
          File(entry.value).existsSync(),
          isTrue,
          reason: '${entry.key} names ${entry.value}, which is missing',
        );
      }
    });
  });

  group('which faces are earning their weight', () {
    /// Families no style asks for.
    Set<String> unused() =>
        declared.keys.toSet()..removeAll(styles.values.whereType<String>());

    test('is none of them, for the first time', () {
      // Every declared face is drawn with. This has not been true for most
      // of the type's life here — at one point five were shipped and unused
      // — and it stays true only if a family dropped from the styles is
      // dropped from the pubspec in the same breath.
      expect(unused(), isEmpty);
    });

    test('and a face whose file is gone is not declared either', () {
      // Seven were deleted from disk in one go. A declaration left pointing
      // at a file that is not there fails the build outright — which is the
      // kind one notices — but the same tidy-up is what leaves a family
      // declared and unused, which is the kind nobody does.
      for (final path in declared.values) {
        expect(File(path).existsSync(), isTrue, reason: '$path is gone');
      }
    });

    test('and every other declared face is drawn with', () {
      for (final family in declared.keys) {
        if (unused().contains(family)) continue;
        expect(
          styles.values,
          contains(family),
          reason: '$family is shipped and never used',
        );
      }
    });
  });

  group('the readout is set in two faces', () {
    test('because the figure is the half that moves', () {
      expect(type.loading.fontFamily, isNot(type.loadingReadout.fontFamily));
    });

    test('and both are tracked, because both are mono', () {
      // How *much* each is tracked is a judgement that has been made and
      // remade, so this asserts only what the two faces are for: a monospaced
      // readout with no tracking at all closes up into a block.
      expect(type.loading.letterSpacing, greaterThan(0));
      expect(type.loadingReadout.letterSpacing, greaterThan(0));
    });
  });
}
