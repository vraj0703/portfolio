import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/style/colors.dart';

void main() {
  group('the page before the app', () {
    final html = File('web/index.html').readAsStringSync();

    test('is already the colour the scene starts on', () {
      // The browser paints `index.html` long before Flutter's first frame.
      // Left white, that frame brings the backdrop and the mark on together
      // and the whole screen arrives in one step — which no in-app easing
      // can soften, because the app is not running yet.
      final backdrop = const DefaultAppColors().loadingBackdrop;
      final hex =
          // ignore: deprecated_member_use
          '#${(backdrop.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

      expect(
        html.toLowerCase(),
        contains('background-color: $hex'),
        reason: 'index.html does not start on the loading backdrop',
      );
    });

    test('and has no margin to show through as a border', () {
      expect(html, contains('margin: 0'));
    });
  });
}
