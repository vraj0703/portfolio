import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/lightmap_bake.dart';
import 'package:vector_math/vector_math.dart';

void main() {
  final up = Vector3(0, 1, 0);

  group('the bake is flutter_scene\'s punctual-light arithmetic', () {
    test('a point light straight above: radiance / d^2 / pi, windowed', () {
      const d = 2.0;
      const range = 10.0;
      final lamp = BakeLamp(
        position: Vector3(0, d, 0),
        radiance: Vector3(4, 4, 4),
        range: range,
      );
      final e = LightmapBake.radianceAt([lamp], Vector3.zero(), up);
      final factor = d * d / (range * range);
      final window = math.pow(1 - factor * factor, 2);
      expect(e.x, closeTo(4 * window / (d * d) / math.pi, 1e-6));
    });

    test('nothing beyond the range, nothing from below', () {
      final far = BakeLamp(
        position: Vector3(0, 5, 0),
        radiance: Vector3.all(9),
        range: 4,
      );
      final below = BakeLamp(
        position: Vector3(0, -1, 0),
        radiance: Vector3.all(9),
        range: 10,
      );
      expect(
        LightmapBake.radianceAt([far, below], Vector3.zero(), up).length,
        0,
      );
    });

    test('a spot lights inside its cone and not outside it', () {
      final spot = BakeLamp(
        position: Vector3(0, 2, 0),
        radiance: Vector3.all(10),
        range: 10,
        direction: Vector3(0, -1, 0),
        outerCone: 0.3,
      );
      expect(
        LightmapBake.radianceAt([spot], Vector3.zero(), up).x,
        greaterThan(0),
      );
      expect(LightmapBake.radianceAt([spot], Vector3(3, 0, 0), up).x, 0);
    });

    test('the level grid adds the ambient, row by row along z', () {
      final ambient = Vector3(0.5, 0.25, 0.125);
      final grid = LightmapBake.level(
        lamps: const [],
        ambient: ambient,
        x0: 0,
        z0: 0,
        x1: 2,
        z1: 3,
        y: 0,
        width: 2,
        height: 3,
      );
      expect(grid.length, 2 * 3 * 3);
      expect(grid.sublist(0, 3), [0.5, 0.25, 0.125]);
    });
  });

  test('RGBM round-trips the way the shader decodes it', () {
    final rgb = Float32List.fromList([0.3, 1.7, 6.0, 0.02, 0.01, 0.0]);
    final bytes = LightmapBake.rgbm(rgb);
    for (var t = 0; t < 2; t++) {
      final a = bytes[t * 4 + 3] / 255;
      final mult = math.pow(a, 2.2) * 34.4932;
      for (var c = 0; c < 3; c++) {
        final decoded = bytes[t * 4 + c] / 255 * mult;
        expect(
          decoded,
          closeTo(rgb[t * 3 + c], 0.02 * math.max(1, rgb[t * 3 + c])),
        );
      }
    }
  });

  test('a face bakes along its own axes, facing its own way', () {
    // A wall facing +x, 4 wide along z and 2 tall, a lamp in front of its
    // u = 0.25 end: the texels nearer the lamp are brighter.
    final lamp = BakeLamp(
      position: Vector3(1, 1, 1),
      radiance: Vector3.all(20),
      range: 10,
    );
    final grid = LightmapBake.face(
      lamps: [lamp],
      ambient: Vector3.zero(),
      origin: Vector3(0, 2, 0),
      uAxis: Vector3(0, 0, 4),
      vAxis: Vector3(0, -2, 0),
      normal: Vector3(1, 0, 0),
      width: 4,
      height: 2,
    );
    double at(int i, int j) => grid[(j * 4 + i) * 3];
    expect(at(0, 0), greaterThan(at(3, 0)));
    // Facing away from the lamp, nothing.
    final back = LightmapBake.face(
      lamps: [lamp],
      ambient: Vector3.zero(),
      origin: Vector3(0, 2, 0),
      uAxis: Vector3(0, 0, 4),
      vAxis: Vector3(0, -2, 0),
      normal: Vector3(-1, 0, 0),
      width: 4,
      height: 2,
    );
    expect(back.every((x) => x == 0), isTrue);
  });
}
