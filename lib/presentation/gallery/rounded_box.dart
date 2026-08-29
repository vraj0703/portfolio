import 'dart:typed_data';

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';

/// A box with its edges and corners rounded off.
///
/// flutter_scene ships a cuboid and nothing softer, and a hard-edged cuboid is
/// the one shape that never occurs in a moulded object. Keycaps and cases are
/// pressed, cast or milled, and every one of them carries a radius — it is the
/// single detail that separates a rendered box from a manufactured thing,
/// because the highlight running along a rounded edge is what tells the eye
/// there is an edge there at all. A hard edge catches no light and reads flat.
///
/// Built by the standard trick rather than by modelling corners: take a
/// subdivided cube, pull every vertex in to an inner box inset by the radius,
/// and push it back out along the direction it came from. Points in the middle
/// of a face come back exactly where they started, so faces stay flat; points
/// near an edge come back on a cylinder, and near a corner on a sphere. One
/// rule, no seams, and the normals fall out of the same direction vector.
abstract final class RoundedBox {
  /// Segments per face edge.
  ///
  /// Six is enough that the radius reads as a curve at the sizes here — a cap
  /// is under thirty centimetres across — without spending vertices on a
  /// shape nobody looks at closely.
  static const int segments = 6;

  /// Radius as a fraction of the box's smallest side, when not given.
  static const double defaultRadiusFactor = 0.18;

  /// The radius actually used for a box of [extents].
  ///
  /// Pure and separate because it is the one part with a rule worth checking:
  /// a radius past half the smallest side leaves no straight section to round
  /// and inverts the inner box, which folds the shape through itself.
  static double radiusFor(Vector3 extents, {double? radius}) {
    final half = extents * 0.5;
    final smallest = <double>[half.x, half.y, half.z].reduce(
      (a, b) => a < b ? a : b,
    );

    return (radius ?? smallest * 2 * defaultRadiusFactor).clamp(
      0.0,
      smallest * 0.999,
    );
  }

  static MeshGeometry build(Vector3 extents, {double? radius}) {
    final mesh = arrays(extents, radius: radius);
    return MeshGeometry.fromArrays(
      positions: Float32List.fromList(mesh.positions),
      normals: Float32List.fromList(mesh.normals),
      texCoords: Float32List.fromList(mesh.texCoords),
      indices: Uint16List.fromList(mesh.indices),
    );
  }

  /// The vertex data, before it goes near a GPU.
  ///
  /// Separate so the shape can actually be checked. The geometry itself
  /// uploads to a device a test harness has not got, and the bug this exists
  /// for was invisible to everything except the eye: two of the six faces
  /// were wound backwards, so the top and bottom of every box were culled and
  /// the visitor could see straight through the keycaps and the case. It
  /// analysed clean, it tested clean, and it looked like transparency.
  static RoundedBoxArrays arrays(Vector3 extents, {double? radius}) {
    final half = extents * 0.5;
    final r = radiusFor(extents, radius: radius);
    final inner = Vector3(half.x - r, half.y - r, half.z - r);

    final positions = <double>[];
    final normals = <double>[];
    final texCoords = <double>[];
    final indices = <int>[];

    // The six faces, each as an axis plus the two axes that span it.
    //
    // The pairs are cyclic — (Y,Z), (Z,X), (X,Y) — and that is load-bearing
    // rather than tidy. Each spanning pair has to be right-handed about its
    // own axis, so that one winding rule holds for all six. Writing the Y
    // face as (X,Z) instead reads perfectly naturally and is left-handed:
    // cross(X, Z) points along -Y, so that face and its opposite come out
    // wound backwards, get culled, and the box loses its lid and its floor.
    const faces = <List<int>>[
      <int>[0, 1, 2],
      <int>[0, 1, 2],
      <int>[1, 2, 0],
      <int>[1, 2, 0],
      <int>[2, 0, 1],
      <int>[2, 0, 1],
    ];

    for (var face = 0; face < 6; face++) {
      final axis = faces[face][0];
      final u = faces[face][1];
      final v = faces[face][2];
      final sign = face.isEven ? 1.0 : -1.0;
      final base = positions.length ~/ 3;

      for (var iv = 0; iv <= segments; iv++) {
        for (var iu = 0; iu <= segments; iu++) {
          final su = iu / segments * 2 - 1;
          final sv = iv / segments * 2 - 1;

          final point = Vector3.zero();
          point[axis] = sign * half[axis];
          point[u] = su * half[u];
          point[v] = sv * half[v];

          // Pull in to the inner box, then push back out by the radius. A
          // point already inside comes back unchanged, which is what keeps
          // the flat middle of each face flat.
          final clamped = Vector3(
            point.x.clamp(-inner.x, inner.x),
            point.y.clamp(-inner.y, inner.y),
            point.z.clamp(-inner.z, inner.z),
          );
          final out = point - clamped;
          final length = out.length;
          final normal = length > 1e-9
              ? out / length
              : (Vector3.zero()..[axis] = sign);
          final finalPoint = clamped + normal * r;

          positions.addAll(<double>[
            finalPoint.x,
            finalPoint.y,
            finalPoint.z,
          ]);
          normals.addAll(<double>[normal.x, normal.y, normal.z]);
          texCoords.addAll(<double>[
            (su + 1) / 2,
            (sv + 1) / 2,
          ]);
        }
      }

      for (var iv = 0; iv < segments; iv++) {
        for (var iu = 0; iu < segments; iu++) {
          final a = base + iv * (segments + 1) + iu;
          final b = a + 1;
          final c = a + segments + 1;
          final d = c + 1;

          // Wound so the face points outward. `iu` runs along `u` and `iv`
          // along `v`, so going a → b → d traverses the quad in the order
          // whose cross product is `u × v` — which the face table guarantees
          // is the outward axis. The negative faces are the same quad seen
          // from behind, so they take the reverse.
          if (sign > 0) {
            indices.addAll(<int>[a, b, d, a, d, c]);
          } else {
            indices.addAll(<int>[a, d, b, a, c, d]);
          }
        }
      }
    }

    return RoundedBoxArrays(
      positions: positions,
      normals: normals,
      texCoords: texCoords,
      indices: indices,
    );
  }
}

/// Vertex data for a rounded box.
class RoundedBoxArrays {
  const RoundedBoxArrays({
    required this.positions,
    required this.normals,
    required this.texCoords,
    required this.indices,
  });

  final List<double> positions;
  final List<double> normals;
  final List<double> texCoords;
  final List<int> indices;

  Vector3 vertexAt(int index) => Vector3(
    positions[index * 3],
    positions[index * 3 + 1],
    positions[index * 3 + 2],
  );

  Vector3 normalAt(int index) => Vector3(
    normals[index * 3],
    normals[index * 3 + 1],
    normals[index * 3 + 2],
  );
}
