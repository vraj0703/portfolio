import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/frame_cadence.dart';

/// Runs [cadence] on a 120 Hz panel where painting a frame costs [paintMs]:
/// a painted tick delays the next tick to the first vsync after the paint.
/// Returns the painted ticks' times.
/// The simulated clock, carried across runs so time only goes forward.
double clock = 0;

List<double> run(FrameCadence cadence, double seconds, double paintMs) {
  const tick = 1000 / 120;
  final painted = <double>[];
  var t = clock;
  final end = clock + seconds * 1000;
  while (t < end) {
    final paint = cadence.tick(t);
    if (paint) {
      painted.add(t);
      t += (paintMs / tick).ceil().clamp(1, 100) * tick;
    } else {
      t += tick;
    }
  }
  clock = t;
  return painted;
}

List<double> intervals(List<double> times) => [
  for (var i = 1; i < times.length; i++) times[i] - times[i - 1],
];

void main() {
  setUp(() => clock = 0);

  test('a phone that holds 60 paints every 2nd tick, evenly', () {
    final c = FrameCadence();
    final p = run(c, 4, 12);
    expect(c.divisor, 2);
    final iv = intervals(p.sublist(p.length ~/ 2));
    expect(iv.every((i) => (i - 1000 / 60).abs() < 0.5), isTrue);
  });

  test('a warm phone (paint 22 ms) settles on an even 40', () {
    final c = FrameCadence();
    final p = run(c, 6, 22);
    expect(c.divisor, 3);
    final iv = intervals(p.sublist(p.length ~/ 2));
    expect(iv.every((i) => (i - 25).abs() < 0.5), isTrue);
  });

  test('a hot phone (paint 30 ms) settles on an even 30', () {
    final c = FrameCadence();
    run(c, 8, 30);
    expect(c.divisor, 4);
  });

  test('it comes back to 60 when the phone cools, without flapping', () {
    final c = FrameCadence();
    run(c, 6, 22);
    expect(c.divisor, 3);
    // Cooler: holds 60 again. Not at once (hysteresis), but within seconds.
    run(c, 1, 12);
    expect(c.divisor, 3, reason: 'one good second is not enough');
    run(c, 6, 12);
    expect(c.divisor, 2);
  });
}
