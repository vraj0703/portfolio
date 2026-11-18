import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The phone DPR cap lives in web/index.html, where it must run before
/// Flutter reads the ratio. Its behaviour in a browser is checked end to
/// end by tool/check_dpr_cap.py (phone 2.625 reads 2, desktops unchanged);
/// this pins what that check depends on.
void main() {
  final html = File('web/index.html').readAsStringSync();
  final cap = html.indexOf("'devicePixelRatio'");

  test('it runs before flutter_bootstrap.js', () {
    expect(cap, greaterThan(0));
    expect(cap, lessThan(html.indexOf('flutter_bootstrap.js"')));
  });

  test('phones only: a coarse pointer and a phone-sized short side', () {
    expect(html, contains("matchMedia('(pointer: coarse)')"));
    expect(html, contains('PHONE_SHORT_SIDE = 600'));
    expect(
      html,
      contains('if (!coarse || shortSide > PHONE_SHORT_SIDE) return;'),
    );
  });

  test('capped at 2, wrapping the browser getter so zoom still counts', () {
    expect(html, contains('CAP = 2'));
    expect(html, contains('Math.min(own.get.call(window), CAP)'));
  });
}
