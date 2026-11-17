import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/presentation/screen/vector_primer.dart';

void main() {
  test('it draws every SVG the app uses', () {
    // The point is that no SvgPicture builds for the first time after the
    // tap: the first one on the web reads a pixel back (490 ms on the ROG).
    // A drawing added later and not listed here would bring that back only
    // if it were the first, but it would also arrive unparsed; list it.
    final used = <String>{};
    final literal = RegExp(r"'(assets/vectors/[^']+\.svg)'");
    for (final f in Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      used.addAll(literal.allMatches(f.readAsStringSync()).map((m) => m[1]!));
    }

    expect(used, isNotEmpty);
    expect(VectorPrimer.drawings.toSet(), used);
  });

  testWidgets('it builds one picture per drawing', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: VectorPrimer(),
      ),
    );

    expect(
      find.byType(SvgPicture),
      findsNWidgets(VectorPrimer.drawings.toSet().length),
    );
  });

  test('the scene shows it only while loading, under the curtain', () {
    final source = File(
      'lib/presentation/screen/scene_view.dart',
    ).readAsStringSync();
    final at = source.indexOf('if (isLoading) const VectorPrimer()');

    expect(at, greaterThan(0));
    expect(at, lessThan(source.indexOf('ClipPath(')));
  });
}
