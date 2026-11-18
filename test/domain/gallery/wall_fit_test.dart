import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/gallery_camera_path.dart';
import 'package:portfolio/domain/gallery/gallery_dimensions.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';
import 'package:portfolio/domain/gallery/gallery_shape.dart';
import 'package:portfolio/domain/gallery/wall_fit.dart';

/// Screens from a tall phone to an ultrawide monitor.
const aspects = <double>[0.42, 0.46, 0.53, 0.75, 1.33, 1.6, 16 / 9, 2.4];

double fovFor(double aspect) => GalleryShape.forAspect(aspect).fovRadians;

void main() {
  group('WallFit', () {
    test('with no margin, the piece exactly fills the narrower axis', () {
      const fovY = 60 * math.pi / 180;
      final d = WallFit.distance(
        width: 4,
        height: 1,
        aspect: 0.5,
        fovY: fovY,
        margin: 0,
      );
      expect(d * math.tan(fovY / 2) * 0.5, closeTo(2, 1e-9));
    });

    test('a tall piece is fitted by its height', () {
      const fovY = 60 * math.pi / 180;
      final d = WallFit.distance(
        width: 1,
        height: 4,
        aspect: 2,
        fovY: fovY,
        margin: 0,
      );
      expect(d * math.tan(fovY / 2), closeTo(2, 1e-9));
    });

    test('a narrower screen stands further back', () {
      double at(double aspect) =>
          WallFit.distance(width: 6, height: 2.4, aspect: aspect, fovY: 1);
      expect(at(0.46), greaterThan(at(1)));
      expect(at(1), greaterThan(at(2)));
    });
  });

  group('the back-wall stop', () {
    test('a desktop stops where it always did, on the alley centre line', () {
      expect(
        GalleryCameraPath.statementStandoff(16 / 9),
        GalleryDimensions.wallLockDistance,
      );
    });

    test('a portrait phone stands back, about nine units', () {
      final d = GalleryCameraPath.statementStandoff(0.46);
      expect(d, greaterThan(8));
      expect(d, lessThan(10));
    });

    for (final aspect in aspects) {
      test(
        'the whole statement fits with a margin at ${aspect.toStringAsFixed(2)}',
        () {
          final stop = GalleryCameraPath.poseAt(
            GalleryCameraPath.walkFraction,
            aspect: aspect,
          );
          final distance = stop.position.z - GalleryDimensions.backWallZ;
          expect(
            WallFit.fits(
              width:
                  GalleryDimensions.statementWidth * (1 + 2 * WallFit.margin),
              // Vector3 is float32: the pose is the standoff to ~1e-7.
              distance: distance + 1e-4,
              aspect: aspect,
              fovY: fovFor(aspect),
            ),
            isTrue,
          );
          // And it is the stop: the walk ends there rather than going on.
          final justBefore = GalleryCameraPath.poseAt(
            GalleryCameraPath.walkFraction * 0.9999,
            aspect: aspect,
          );
          expect(justBefore.position.z, closeTo(stop.position.z, 0.01));
        },
      );
    }

    test('the walk stays inside the corridor, short of its entrance', () {
      for (final aspect in aspects) {
        final d = GalleryCameraPath.statementStandoff(aspect);
        final start = GalleryCameraPath.startZFor(aspect);
        expect(
          GalleryDimensions.backWallZ + d,
          lessThan(start),
          reason: 'aspect $aspect',
        );
      }
    });
  });

  group('stepping in to the alley', () {
    for (final aspect in aspects) {
      test(
        'never walks through the corridor wall at ${aspect.toStringAsFixed(2)}',
        () {
          // Where the corridor's side wall stands, the camera has to be in the
          // alley's depth already.
          final wallX = GalleryShape.forAspect(aspect).wallX;
          final alleyFront =
              GalleryDimensions.backWallZ + GalleryDimensions.wingWidth;
          for (var x = 0.0; x <= GalleryCameraPath.panEndX; x += 0.05) {
            final z = GalleryCameraPath.panZ(x, aspect);
            if (x >= wallX - 0.5) {
              expect(z, lessThan(alleyFront - 0.3), reason: 'x $x');
            }
          }
        },
      );

      test(
        'is continuous from the walk to the hall at ${aspect.toStringAsFixed(2)}',
        () {
          var last = GalleryCameraPath.poseAt(0, aspect: aspect).position;
          for (var p = 0.0; p <= 1.0; p += 0.0005) {
            final at = GalleryCameraPath.poseAt(p, aspect: aspect).position;
            expect((at - last).length, lessThan(0.25), reason: 'at $p');
            last = at;
          }
        },
      );
    }

    test('reaches the doorway on the alley centre line', () {
      for (final aspect in aspects) {
        final p =
            GalleryCameraPath.panEnd +
            GalleryCameraPath.doorwayShare * GalleryCameraPath.hallFraction;
        expect(
          GalleryCameraPath.poseAt(p, aspect: aspect).position.z,
          closeTo(GalleryDimensions.wallLockZ, 1e-9),
          reason: 'aspect $aspect',
        );
      }
    });
  });

  group('the testimonial wall', () {
    test('a desktop pans on the alley centre line, as it always did', () {
      expect(
        GalleryCameraPath.testimonialStandoff(16 / 9),
        GalleryDimensions.wallLockDistance,
      );
    });

    for (final aspect in aspects) {
      test('a whole card is in view at ${aspect.toStringAsFixed(2)}', () {
        // At each card's own x, square-on, from where the pan runs.
        for (var i = 0; i < GalleryDimensions.testimonialCount; i++) {
          final x =
              GalleryDimensions.testStartX + i * GalleryDimensions.testSpacing;
          final distance =
              GalleryCameraPath.panZ(x, aspect) -
              (GalleryDimensions.backWallZ + GalleryLayout.testimonialStandoff);
          // The tallest screens (a 21:9 phone with no browser bars) would
          // need to stand outside the alley for the whole card; there the
          // card is at least 90% in view, and from 0.46 up it is whole.
          final shown = aspect < 0.45 ? 0.9 : 1.0;
          expect(
            WallFit.fits(
              width: GalleryLayout.frameWidth * shown,
              distance: distance + 1e-4,
              aspect: aspect,
              fovY: fovFor(aspect),
            ),
            isTrue,
            reason: 'card $i',
          );
        }
      });

      test(
        'the pan stays inside the alley at ${aspect.toStringAsFixed(2)}',
        () {
          expect(
            GalleryCameraPath.testimonialStandoff(aspect),
            lessThanOrEqualTo(
              GalleryDimensions.wingWidth - GalleryCameraPath.alleyClearance,
            ),
          );
        },
      );
    }

    test('a portrait phone stands back further than a desktop', () {
      expect(
        GalleryCameraPath.testimonialStandoff(0.46),
        greaterThan(GalleryCameraPath.testimonialStandoff(16 / 9) + 2),
      );
    });
  });
}
