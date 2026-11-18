import 'dart:math' as math;
import 'dart:typed_data';

import 'package:vector_math/vector_math.dart';

/// A lamp as the renderer sees it: engine space, its colour already
/// multiplied by its intensity.
class BakeLamp {
  const BakeLamp({
    required this.position,
    required this.radiance,
    required this.range,
    this.direction,
    this.innerCone = 0,
    this.outerCone = 0,
    this.falloffExponent = 2,
  });

  final Vector3 position;

  /// Colour times intensity: what the renderer packs for the light.
  final Vector3 radiance;

  /// The light's reach; 0 is unlimited.
  final double range;

  /// Where a spot points; null for a point light.
  final Vector3? direction;

  /// A spot's cone half-angles, in radians.
  final double innerCone;
  final double outerCone;

  final double falloffExponent;

  bool get isSpot => direction != null;
}

/// The lamp pools of a level surface, baked once, so a phone can draw them
/// from a texture instead of shading every lamp at every pixel.
///
/// The arithmetic is flutter_scene 0.23's own for a punctual light
/// (`material_lighting.glsl`): a windowed falloff,
/// `clamp(1 - (d^2 / r^2)^2, 0, 1)^2 / d^e`, a squared linear cone ramp for a
/// spot, and Lambert's `n.l / pi` for the diffuse term. The result stands in
/// for the environment's ambient (a bound lightmap replaces it), so the
/// ambient is added here too. Same lamps, same formula: the baked pools and
/// the live ones cannot drift apart.
abstract final class LightmapBake {
  /// Radiance at each texel of the level region `x0..x1` by `z0..z1` at
  /// height [y], facing up: [width] by [height] texels, rows along z, three
  /// floats (rgb) per texel.
  static Float32List level({
    required List<BakeLamp> lamps,
    required Vector3 ambient,
    required double x0,
    required double z0,
    required double x1,
    required double z1,
    required double y,
    required int width,
    required int height,
  }) => face(
    lamps: lamps,
    ambient: ambient,
    origin: Vector3(x0, y, z0),
    uAxis: Vector3(x1 - x0, 0, 0),
    vAxis: Vector3(0, 0, z1 - z0),
    normal: Vector3(0, 1, 0),
    width: width,
    height: height,
  );

  /// Radiance over a rectangular face: the texel at (u, v) sits at
  /// `origin + uAxis * u + vAxis * v`, facing [normal]; [width] by [height]
  /// texels, rows along v, three floats a texel. For a wall, a ceiling, any
  /// flat side of a box.
  ///
  /// A scalar loop over lamps packed once, with nothing allocated per texel
  /// and lamps out of range rejected first: the vector version cost about
  /// 12 s of loading on the ROG Phone II.
  static Float32List face({
    required List<BakeLamp> lamps,
    required Vector3 ambient,
    required Vector3 origin,
    required Vector3 uAxis,
    required Vector3 vAxis,
    required Vector3 normal,
    required int width,
    required int height,
  }) {
    final packed = _pack(lamps);
    final n = normal.normalized();
    final acc = Float64List(3);
    final out = Float32List(width * height * 3);
    for (var j = 0; j < height; j++) {
      final v = (j + 0.5) / height;
      for (var i = 0; i < width; i++) {
        final u = (i + 0.5) / width;
        final x = origin.x + uAxis.x * u + vAxis.x * v;
        final y = origin.y + uAxis.y * u + vAxis.y * v;
        final z = origin.z + uAxis.z * u + vAxis.z * v;
        acc[0] = ambient.x;
        acc[1] = ambient.y;
        acc[2] = ambient.z;
        _accumulate(packed, lamps.length, x, y, z, n.x, n.y, n.z, acc);
        final k = (j * width + i) * 3;
        out[k] = acc[0];
        out[k + 1] = acc[1];
        out[k + 2] = acc[2];
      }
    }
    return out;
  }

  /// The lamps' diffuse contribution at [point] for a surface facing
  /// [normal], before the surface's own colour.
  static Vector3 radianceAt(
    List<BakeLamp> lamps,
    Vector3 point,
    Vector3 normal,
  ) {
    final acc = Float64List(3);
    final n = normal.normalized();
    _accumulate(
      _pack(lamps),
      lamps.length,
      point.x,
      point.y,
      point.z,
      n.x,
      n.y,
      n.z,
      acc,
    );
    return Vector3(acc[0], acc[1], acc[2]);
  }

  /// Floats per packed lamp: position, radiance, inverse range, normalised
  /// direction, cone scale and offset, spot flag, half the falloff exponent.
  static const int _stride = 14;

  static Float64List _pack(List<BakeLamp> lamps) {
    final out = Float64List(lamps.length * _stride);
    for (var i = 0; i < lamps.length; i++) {
      final lamp = lamps[i];
      final b = i * _stride;
      out[b] = lamp.position.x;
      out[b + 1] = lamp.position.y;
      out[b + 2] = lamp.position.z;
      out[b + 3] = lamp.radiance.x;
      out[b + 4] = lamp.radiance.y;
      out[b + 5] = lamp.radiance.z;
      out[b + 6] = lamp.range > 0 ? 1 / lamp.range : 0;
      final dir = lamp.direction;
      if (dir != null) {
        final d = dir.normalized();
        final cosInner = math.cos(lamp.innerCone);
        final cosOuter = math.cos(lamp.outerCone);
        final scale = 1 / math.max(cosInner - cosOuter, 1e-4);
        out[b + 7] = d.x;
        out[b + 8] = d.y;
        out[b + 9] = d.z;
        out[b + 10] = scale;
        out[b + 11] = -cosOuter * scale;
        out[b + 12] = 1;
      }
      out[b + 13] = lamp.falloffExponent / 2;
    }
    return out;
  }

  /// Adds every lamp's term at (x, y, z) facing (nx, ny, nz) into [acc]:
  /// flutter_scene's windowed falloff, squared cone ramp and n.l / pi.
  static void _accumulate(
    Float64List lamps,
    int count,
    double x,
    double y,
    double z,
    double nx,
    double ny,
    double nz,
    Float64List acc,
  ) {
    for (var i = 0; i < count; i++) {
      final b = i * _stride;
      final tx = lamps[b] - x, ty = lamps[b + 1] - y, tz = lamps[b + 2] - z;
      final d2 = tx * tx + ty * ty + tz * tz;
      if (d2 <= 1e-8) continue;
      final inv = lamps[b + 6];
      final factor = d2 * inv * inv;
      if (inv > 0 && factor >= 1) continue;
      final dist = math.sqrt(d2);
      final lx = tx / dist, ly = ty / dist, lz = tz / dist;
      final nl = nx * lx + ny * ly + nz * lz;
      if (nl <= 0) continue;
      final window = inv > 0 ? 1 - factor * factor : 1.0;
      final half = lamps[b + 13];
      final falloff = half == 1 ? d2 : math.pow(d2, half).toDouble();
      var scale = window * window / math.max(falloff, 1e-4);
      if (lamps[b + 12] > 0.5) {
        final cd = -(lamps[b + 7] * lx + lamps[b + 8] * ly + lamps[b + 9] * lz);
        final cone = (cd * lamps[b + 10] + lamps[b + 11]).clamp(0.0, 1.0);
        if (cone <= 0) continue;
        scale *= cone * cone;
      }
      final w = scale * nl / math.pi;
      acc[0] += lamps[b + 3] * w;
      acc[1] += lamps[b + 4] * w;
      acc[2] += lamps[b + 5] * w;
    }
  }

  /// RGBM-packs linear [rgb] radiance (three floats a texel) into RGBA bytes,
  /// the encoding flutter_scene decodes as `rgb * a^2.2 * 34.4932`.
  static Uint8List rgbm(Float32List rgb) {
    const range = 34.4932;
    final texels = rgb.length ~/ 3;
    final out = Uint8List(texels * 4);
    for (var t = 0; t < texels; t++) {
      final r = rgb[t * 3], g = rgb[t * 3 + 1], b = rgb[t * 3 + 2];
      final m = math.max(math.max(r, g), math.max(b, 1e-6)) / range;
      // The multiplier is stored gamma-encoded and rounded up, so rgb <= 1.
      final a = (math.pow(m.clamp(0.0, 1.0), 1 / 2.2) * 255).ceil().clamp(
        1,
        255,
      );
      final mult = math.pow(a / 255, 2.2) * range;
      out[t * 4] = (r / mult * 255).round().clamp(0, 255);
      out[t * 4 + 1] = (g / mult * 255).round().clamp(0, 255);
      out[t * 4 + 2] = (b / mult * 255).round().clamp(0, 255);
      out[t * 4 + 3] = a;
    }
    return out;
  }
}
