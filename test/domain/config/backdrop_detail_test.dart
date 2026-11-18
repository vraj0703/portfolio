import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/config/backdrop_detail.dart';

void main() {
  final shader = File(
    'assets/shaders/background_run_v2.frag',
  ).readAsStringSync();
  int bound(String loopVar) => int.parse(
    RegExp(
      'for ?\\(int $loopVar = 0; $loopVar < (\\d+); $loopVar\\+\\+\\)',
    ).firstMatch(shader)!.group(1)!,
  );

  group('desktop draws exactly what it drew before', () {
    test('the full detail is the shader\'s own loop bounds, at scale 1', () {
      // With every march and every octave run and each step unscaled, the
      // uniforms change nothing: d += s * 1.0 and o += 1.0 / s are the old
      // arithmetic exactly.
      expect(BackdropDetail.full.steps, bound('i'));
      expect(BackdropDetail.full.octaves, bound('k'));
      expect(BackdropDetail.full.stepScale, 1.0);
    });

    test('and desktops and tablets get it', () {
      expect(BackdropDetail.forDevice(phone: false), same(BackdropDetail.full));
    });
  });

  group('phones march fewer, longer steps', () {
    test('within the shader\'s bounds', () {
      const phone = BackdropDetail.phone;
      expect(phone.steps, lessThan(bound('i')));
      expect(phone.octaves, lessThan(bound('k')));
      expect(phone.stepScale, greaterThan(1));
      expect(BackdropDetail.forDevice(phone: true), same(phone));
    });

    test('covering about the same distance as the full march', () {
      // Fewer steps alone darkened the dunes (variant B); each step is
      // lengthened so the march still reaches them.
      const phone = BackdropDetail.phone;
      const full = BackdropDetail.full;
      final reach =
          phone.steps * phone.stepScale / (full.steps * full.stepScale);
      expect(reach, closeTo(1, 0.05));
    });
  });

  test(
    'the shader reads the three uniforms where the loops and the march are',
    () {
      expect(shader, contains('if (float(i) >= uSteps) break;'));
      expect(shader, contains('if (float(k) >= uOctaves) break;'));
      expect(shader, contains('d += s * uStepScale;'));
      expect(shader, contains('o += uStepScale / s;'));
    },
  );

  test('the backdrop binds them after resolution and time', () {
    final component = File(
      'lib/presentation/game/backdrop_component.dart',
    ).readAsStringSync();
    expect(component, contains('..setFloat(3, detail.steps.toDouble())'));
    expect(component, contains('..setFloat(4, detail.octaves.toDouble())'));
    expect(component, contains('..setFloat(5, detail.stepScale)'));
  });
}
