import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/config/corridor_projection.dart';

const Size viewport = Size(1280, 720);

CorridorProjection cameraAt({double x = 0, double y = 0, double z = 0}) =>
    CorridorProjection(
      viewport: viewport,
      cameraX: x,
      cameraY: y,
      cameraZ: z,
    );

void main() {
  group('CorridorProjection', () {
    test('a point straight ahead lands in the middle of the screen', () {
      final p = cameraAt().project(0, 0, -10);

      expect(p.isVisible, isTrue);
      expect(p.position.dx, closeTo(viewport.width / 2, 0.01));
      expect(p.position.dy, closeTo(viewport.height / 2, 0.01));
    });

    test('things to the right of the camera land right of centre', () {
      final p = cameraAt().project(2, 0, -10);
      expect(p.position.dx, greaterThan(viewport.width / 2));
    });

    test('world up is screen up', () {
      // The axes disagree — world y grows upward, screen y grows downward —
      // and getting it wrong flips the whole corridor without failing.
      final p = cameraAt().project(0, 2, -10);
      expect(p.position.dy, lessThan(viewport.height / 2));
    });

    test('the camera advances by decreasing its own z', () {
      final far = cameraAt(z: 0).project(2, 0, -20);
      final near = cameraAt(z: -10).project(2, 0, -20);

      expect(near.scale, greaterThan(far.scale));
      expect(near.depth, lessThan(far.depth));
    });

    test('things shrink with distance, in inverse proportion', () {
      final near = cameraAt().project(0, 0, -10);
      final far = cameraAt().project(0, 0, -20);

      expect(far.scale, closeTo(near.scale / 2, 0.001));
    });

    test('the same world span covers less screen as it recedes', () {
      final projection = cameraAt();
      expect(
        projection.screenWidthOf(8, 20),
        lessThan(projection.screenWidthOf(8, 10)),
      );
    });

    test('a wall at the corridor edge stays put as the camera advances', () {
      // The corridor's walls are parallel to the camera's path, so their
      // apparent position should converge toward the vanishing point rather
      // than drifting sideways.
      final projection = cameraAt();
      final near = projection.project(-4, 0, -5);
      final far = projection.project(-4, 0, -40);

      expect(near.position.dx, lessThan(far.position.dx));
      expect(far.position.dx, lessThan(viewport.width / 2));
    });
  });

  group('clipping', () {
    test('anything level with or behind the camera is dropped', () {
      // Without a near plane this divides by ~zero and flings the geometry
      // across the screen — the classic way a projected scene explodes.
      expect(cameraAt().project(0, 0, 0).isVisible, isFalse);
      expect(cameraAt().project(0, 0, 5).isVisible, isFalse);
    });

    test('anything past the far plane is dropped', () {
      final beyond = -CorridorProjection.farPlane - 1;
      expect(cameraAt().project(0, 0, beyond).isVisible, isFalse);
    });

    test('a hidden point reports nothing usable', () {
      final p = cameraAt().project(0, 0, 5);
      expect(p.isVisible, isFalse);
      expect(p.scale, 0);
    });

    test('stays finite everywhere along the corridor', () {
      final projection = cameraAt();
      for (var z = 5.0; z > -100; z -= 0.5) {
        final p = projection.project(-4, 2, z);
        if (!p.isVisible) continue;

        expect(p.position.dx.isFinite, isTrue, reason: 'at z=$z');
        expect(p.position.dy.isFinite, isTrue, reason: 'at z=$z');
        expect(p.scale, greaterThan(0), reason: 'at z=$z');
      }
    });
  });

  group('fog', () {
    test('near geometry is untouched', () {
      expect(CorridorProjection.fogAt(0), 0);
      expect(CorridorProjection.fogAt(20), 0);
    });

    test('the far end is fully swallowed', () {
      expect(CorridorProjection.fogAt(80), 1);
      expect(CorridorProjection.fogAt(200), 1);
    });

    test('it comes on gradually between', () {
      // A hard cut-off reads as a wall across the corridor rather than as
      // distance.
      final mid = CorridorProjection.fogAt(52.5);
      expect(mid, greaterThan(0.4));
      expect(mid, lessThan(0.6));
    });

    test('never runs backwards', () {
      var previous = 0.0;
      for (var d = 0.0; d < 120; d += 1) {
        final fog = CorridorProjection.fogAt(d);
        expect(fog, greaterThanOrEqualTo(previous));
        previous = fog;
      }
    });
  });

  group('field of view', () {
    test('a wider lens makes everything smaller', () {
      final narrow = CorridorProjection(
        viewport: viewport,
        cameraX: 0,
        cameraY: 0,
        cameraZ: 0,
        fovRadians: 40 * 3.14159 / 180,
      );
      final wide = CorridorProjection(
        viewport: viewport,
        cameraX: 0,
        cameraY: 0,
        cameraZ: 0,
        fovRadians: 90 * 3.14159 / 180,
      );

      expect(
        wide.project(0, 1, -10).scale,
        lessThan(narrow.project(0, 1, -10).scale),
      );
    });

    test('the viewport height spans exactly the field of view', () {
      final projection = cameraAt();
      // A point one focal length away, half a viewport-height off centre,
      // should land exactly on the top edge.
      final halfHeightWorld =
          (viewport.height / 2) / projection.focalLength * 10;
      final p = projection.project(0, halfHeightWorld, -10);

      expect(p.position.dy, closeTo(0, 0.5));
    });
  });
}
