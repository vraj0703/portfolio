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
  }) {
    final out = Float32List(width * height * 3);
    final p = Vector3.zero();
    for (var j = 0; j < height; j++) {
      final z = z0 + (j + 0.5) / height * (z1 - z0);
      for (var i = 0; i < width; i++) {
        final x = x0 + (i + 0.5) / width * (x1 - x0);
        p.setValues(x, y, z);
        final e = radianceAt(lamps, p, Vector3(0, 1, 0))..add(ambient);
        final k = (j * width + i) * 3;
        out[k] = e.x;
        out[k + 1] = e.y;
        out[k + 2] = e.z;
      }
    }
    return out;
  }

  /// Radiance over a rectangular face: the texel at (u, v) sits at
  /// `origin + uAxis * u + vAxis * v`, facing [normal]; [width] by [height]
  /// texels, rows along v, three floats a texel. For a wall, a ceiling, any
  /// flat side of a box.
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
    final out = Float32List(width * height * 3);
    for (var j = 0; j < height; j++) {
      final v = (j + 0.5) / height;
      for (var i = 0; i < width; i++) {
        final u = (i + 0.5) / width;
        final p = origin + uAxis * u + vAxis * v;
        final e = radianceAt(lamps, p, normal)..add(ambient);
        final k = (j * width + i) * 3;
        out[k] = e.x;
        out[k + 1] = e.y;
        out[k + 2] = e.z;
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
    final sum = Vector3.zero();
    for (final lamp in lamps) {
      final toLight = lamp.position - point;
      final d2 = toLight.length2;
      if (d2 <= 1e-8) continue;
      final l = toLight / math.sqrt(d2);
      final nl = normal.dot(l);
      if (nl <= 0) continue;

      final inv = lamp.range > 0 ? 1 / lamp.range : 0.0;
      final factor = d2 * inv * inv;
      final window = (1 - factor * factor).clamp(0.0, 1.0);
      var scale =
          window *
          window /
          math.max(math.pow(d2, lamp.falloffExponent / 2).toDouble(), 1e-4);

      final dir = lamp.direction;
      if (dir != null) {
        final cosInner = math.cos(lamp.innerCone);
        final cosOuter = math.cos(lamp.outerCone);
        final s = 1 / math.max(cosInner - cosOuter, 1e-4);
        final cd = dir.normalized().dot(-l);
        final cone = (cd * s - cosOuter * s).clamp(0.0, 1.0);
        scale *= cone * cone;
      }
      sum.add(lamp.radiance * (scale * nl / math.pi));
    }
    return sum;
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
