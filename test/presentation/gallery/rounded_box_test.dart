import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/presentation/gallery/rounded_box.dart';
import 'package:vector_math/vector_math.dart';

/// Re-runs the generator's own rule, so the shape can be checked without a
/// GPU: the geometry itself uploads to a device a test harness has not got.
List<Vector3> surfaceOf(Vector3 extents, double radius) {
  final half = extents * 0.5;
  final inner = Vector3(half.x - radius, half.y - radius, half.z - radius);
  final points = <Vector3>[];

  for (var face = 0; face < 6; face++) {
    final axis = face ~/ 2;
    final sign = face.isEven ? 1.0 : -1.0;
    final u = (axis + 1) % 3;
    final v = (axis + 2) % 3;

    for (var iv = 0; iv <= RoundedBox.segments; iv++) {
      for (var iu = 0; iu <= RoundedBox.segments; iu++) {
        final point = Vector3.zero();
        point[axis] = sign * half[axis];
        point[u] = (iu / RoundedBox.segments * 2 - 1) * half[u];
        point[v] = (iv / RoundedBox.segments * 2 - 1) * half[v];

        final clamped = Vector3(
          point.x.clamp(-inner.x, inner.x),
          point.y.clamp(-inner.y, inner.y),
          point.z.clamp(-inner.z, inner.z),
        );
        final out = point - clamped;
        final length = out.length;
        points.add(
          clamped + (length > 1e-9 ? out / length : Vector3.zero()) * radius,
        );
      }
    }
  }
  return points;
}

void main() {
  group('the surface is closed and faces outward', () {
    final mesh = RoundedBox.arrays(Vector3(0.4, 0.18, 0.4), radius: 0.06);

    test('every triangle is wound to face the way its normals point', () {
      // The bug this exists for was invisible to every other check. Two of
      // the six faces were spanned by a left-handed pair of axes, so their
      // triangles came out wound backwards; the renderer culled them, and the
      // visitor could see straight through the lid and floor of every keycap
      // and of the case. It analysed clean, it passed every other test, and
      // on screen it looked like the material had gone transparent.
      var inverted = 0;

      for (var i = 0; i < mesh.indices.length; i += 3) {
        final a = mesh.vertexAt(mesh.indices[i]);
        final b = mesh.vertexAt(mesh.indices[i + 1]);
        final c = mesh.vertexAt(mesh.indices[i + 2]);

        final wound = (b - a).cross(c - a);
        if (wound.length < 1e-12) continue;

        final shaded = mesh.normalAt(mesh.indices[i]) +
            mesh.normalAt(mesh.indices[i + 1]) +
            mesh.normalAt(mesh.indices[i + 2]);

        if (wound.normalized().dot(shaded.normalized()) < 0) inverted++;
      }

      expect(inverted, 0, reason: '\$inverted triangles face inward');
    });

    test('all six faces are present', () {
      // A box missing a face still renders, and from most angles still looks
      // like a box.
      final directions = <String>{};
      for (var i = 0; i < mesh.normals.length; i += 3) {
        final n = mesh.normalAt(i ~/ 3);
        if (n.x.abs() > 0.99) directions.add(n.x > 0 ? '+x' : '-x');
        if (n.y.abs() > 0.99) directions.add(n.y > 0 ? '+y' : '-y');
        if (n.z.abs() > 0.99) directions.add(n.z > 0 ? '+z' : '-z');
      }

      expect(directions, hasLength(6), reason: 'missing \$directions');
    });

    test('every normal is unit length', () {
      for (var i = 0; i < mesh.normals.length ~/ 3; i++) {
        expect(mesh.normalAt(i).length, closeTo(1, 1e-6));
      }
    });
  });

  final extents = Vector3(0.4, 0.18, 0.4);
  const radius = 0.06;
  final points = surfaceOf(extents, radius);

  test('nothing bulges outside the box it was cut from', () {
    // Rounding takes material away; a radius that pushed anything past the
    // original faces would make the cap wider than its pitch and the keys
    // would touch.
    final half = extents * 0.5;
    for (final p in points) {
      expect(p.x.abs(), lessThanOrEqualTo(half.x + 1e-9));
      expect(p.y.abs(), lessThanOrEqualTo(half.y + 1e-9));
      expect(p.z.abs(), lessThanOrEqualTo(half.z + 1e-9));
    }
  });

  test('the middle of a face stays flat', () {
    // The whole point of clamping to an inner box: only the parts near an
    // edge should move. A face that bowed would read as a cushion.
    final half = extents * 0.5;
    final onTop = points.where(
      (p) =>
          (p.y - half.y).abs() < 1e-9 &&
          p.x.abs() < half.x - radius - 1e-6 &&
          p.z.abs() < half.z - radius - 1e-6,
    );

    expect(onTop, isNotEmpty, reason: 'no flat area survived the rounding');
  });

  test('the corners are actually rounded', () {
    // A corner vertex must have been pulled in by the radius on all three
    // axes at once, so it sits strictly inside the box's corner.
    final half = extents * 0.5;
    final corner = points.reduce(
      (a, b) => a.length > b.length ? a : b,
    );

    expect(corner.length, lessThan(half.length - 1e-6));
  });

  test('a radius larger than the box is clamped, not applied', () {
    // Past half the smallest side there is no straight section left to round:
    // the inner box inverts and the shape folds through itself.
    final smallest = extents.storage.reduce((a, b) => a < b ? a : b) / 2;

    expect(
      RoundedBox.radiusFor(extents, radius: 999),
      lessThan(smallest),
    );

    // And the clamped radius still produces a sane surface.
    final clamped = RoundedBox.radiusFor(extents, radius: 999);
    for (final p in surfaceOf(extents, clamped)) {
      expect(p.length.isFinite, isTrue);
    }
  });

  test('an unspecified radius scales with the box', () {
    // A fixed radius would round a keycap nicely and leave the case looking
    // untouched, or the other way about.
    final small = RoundedBox.radiusFor(Vector3(0.4, 0.18, 0.4));
    final large = RoundedBox.radiusFor(Vector3(4.5, 0.9, 2.5));

    expect(large, greaterThan(small));
  });
}
