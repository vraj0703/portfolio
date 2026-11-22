import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/card_homography.dart';

void main() {
  group('the page laid on the card in perspective (live in the corridor)', () {
    const quad = <(double, double)>[
      (300, 120),
      (900, 160),
      (880, 560),
      (320, 600),
    ];

    test('the page corners land on the card corners', () {
      final m = cardMatrix3d(width: 1424, height: 1024, corners: quad)!;
      final pageCorners = <(double, double)>[
        (0, 0),
        (1424, 0),
        (1424, 1024),
        (0, 1024),
      ];
      for (var i = 0; i < 4; i++) {
        final (x, y) = applyMatrix3d(m, pageCorners[i].$1, pageCorners[i].$2);
        expect(x, closeTo(quad[i].$1, 1e-6));
        expect(y, closeTo(quad[i].$2, 1e-6));
      }
    });

    test('an axis-aligned card is a plain scale and translate', () {
      final m = cardMatrix3d(
        width: 1424,
        height: 1024,
        corners: const <(double, double)>[
          (10, 20),
          (722, 20),
          (722, 532),
          (10, 532),
        ],
      )!;
      expect(m[0], closeTo(0.5, 1e-9));
      expect(m[5], closeTo(0.5, 1e-9));
      expect(m[3], closeTo(0, 1e-12));
      expect(m[7], closeTo(0, 1e-12));
    });

    test('a degenerate quad gives nothing', () {
      expect(
        cardMatrix3d(
          width: 1424,
          height: 1024,
          corners: const <(double, double)>[(0, 0), (0, 0), (0, 0), (0, 0)],
        ),
        isNull,
      );
    });

    test(
      'facing the camera is clockwise on the screen; its share is its area',
      () {
        expect(quadArea(quad), greaterThan(0));
        expect(quadArea(quad.reversed.toList()), lessThan(0));
        expect(quadShare(quad, 1280, 800), inExclusiveRange(0, 1));
      },
    );
  });
}
