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

  group('the corridor placement (the hybrid)', () {
    // A card well in view on a 1280 x 800 screen: top pair, then bottom pair.
    const corners = <(double, double)?>[
      (300, 120),
      (900, 160),
      (880, 560),
      (320, 600),
    ];

    CorridorPlacement? place(List<(double, double)?> c, {bool facing = true}) =>
        corridorPlacement(
          corners: c,
          facing: facing,
          viewWidth: 1280,
          viewHeight: 800,
          pageWidth: 1424,
          pageHeight: 1024,
          shareFrom: 0.03,
          shareFull: 0.06,
        );

    test(
      'four projected corners give the matrix that lands the page on them',
      () {
        final placed = place(corners)!;
        expect(placed.opacity, 1);
        final (x, y) = applyMatrix3d(placed.matrix, 1424, 1024);
        expect(x, closeTo(880, 1e-6));
        expect(y, closeTo(560, 1e-6));
      },
    );

    test('the corners may come in either order along each edge', () {
      final swapped = <(double, double)?>[
        corners[1],
        corners[0],
        corners[3],
        corners[2],
      ];
      final (x, y) = applyMatrix3d(place(swapped)!.matrix, 0, 0);
      expect(x, closeTo(300, 1e-6));
      expect(y, closeTo(120, 1e-6));
    });

    test('a corner behind the camera hides it: the picture shows', () {
      expect(
        place(<(double, double)?>[corners[0], null, corners[2], corners[3]]),
        isNull,
      );
    });

    test('a card facing away hides it', () {
      expect(place(corners, facing: false), isNull);
    });

    test('a card too small on the screen hides it', () {
      // 40 x 30 px of 1280 x 800: about 0.1 % of the screen.
      expect(
        place(const <(double, double)?>[
          (10, 10),
          (50, 10),
          (50, 40),
          (10, 40),
        ]),
        isNull,
      );
    });
  });

  group('the share rule', () {
    double o(double share) => corridorOpacity(share, from: 0.03, full: 0.06);

    test('the picture below 3 % of the screen, the live page from 6 %', () {
      expect(o(0), 0);
      expect(o(0.03), 0);
      expect(o(0.06), 1);
      expect(o(0.5), 1);
    });

    test('a straight fade between, so it never pops', () {
      expect(o(0.045), closeTo(0.5, 1e-9));
      expect(o(0.04), lessThan(o(0.05)));
    });
  });
}
