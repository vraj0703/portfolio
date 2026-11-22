import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/contact/credits.dart';

/// Every file the site ships from assets/ and fonts/, from the repository.
List<String> _shipped() {
  final out = <String>[];
  for (final root in <String>['assets', 'fonts']) {
    for (final f in Directory(root).listSync(recursive: true)) {
      if (f is File) out.add(f.path.replaceAll(r'\', '/'));
    }
  }
  return out;
}

void main() {
  group('the credits record (PORTFOLIO-31)', () {
    test('every file under assets/ and fonts/ has an entry', () {
      final missing = <String>[
        for (final path in _shipped())
          if (!Credits.items.any((i) => i.covers(path))) path,
      ];
      expect(missing, isEmpty, reason: 'add these to Credits.items');
    });

    test(
      'docs/CREDITS.md mirrors the record (dart run tool/write_credits.dart)',
      () {
        expect(
          File('docs/CREDITS.md').readAsStringSync().replaceAll('\r\n', '\n'),
          Credits.markdown(),
        );
      },
    );

    test(
      'the dialog never says UNKNOWN nor names an author it does not know',
      () {
        final shown = Credits.groups.expand((g) => g.items).toList();
        expect(shown.where((l) => l.contains(Credits.unknown)), isEmpty);
        for (final item in Credits.items) {
          if (item.status != CreditStatus.unknown) continue;
          expect(item.author, Credits.unknown, reason: item.what);
          final line = item.line;
          if (line == null) continue;
          // Name and use only: "<name> — <use>", no "by".
          expect(line, isNot(contains(' by ')), reason: line);
        }
      },
    );

    test('credit the dialog already gave is kept: the fonts by name', () {
      final type = Credits.groups.firstWhere((g) => g.heading == 'Type').items;
      expect(
        type,
        containsAll(<String>[
          'Apertura — the titles',
          'Modrnt Urban — the mark',
          'MonoLoading — the loading readout',
          'Margot — the text',
        ]),
      );
    });

    test('what cannot be named stays out until Vishal answers', () {
      for (final path in <String>[
        'assets/shaders/logo.frag',
        'assets/objects/arrow.glb',
        'assets/vectors/circle.svg',
        'web/og-image.jpg',
      ]) {
        final item = Credits.items.firstWhere((i) => i.covers(path));
        expect(item.line, isNull, reason: path);
      }
    });

    test('Poly Haven is gone: nothing of theirs is used', () {
      final all = Credits.items.map((i) => '${i.what} ${i.author} ${i.line}');
      expect(all.any((s) => s.contains('Poly Haven')), isFalse);
    });

    test('the known fonts carry their checked licence', () {
      final marcellus = Credits.items.firstWhere(
        (i) => i.what == 'Font Marcellus',
      );
      expect(marcellus.author, 'Astigmatic');
      expect(marcellus.licence, contains('Open Font License'));
      final azeret = Credits.items.firstWhere(
        (i) => i.what == 'Font Azeret Mono',
      );
      expect(azeret.author, contains('Displaay'));
    });
  });
}
