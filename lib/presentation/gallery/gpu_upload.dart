import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_scene/scene.dart';
// The texture is created through the package's own GPU shim, which it does
// not export. flutter_scene is pinned to an exact version in pubspec.yaml,
// and test/presentation/gallery/gpu_upload_test.dart checks the chain built
// here against the package's own generator byte for byte, so an upgrade that
// changes either side fails the tests rather than the picture.
// ignore: implementation_imports
import 'package:flutter_scene/src/gpu/gpu.dart' as gpu;

/// One level of a mip chain: straight-alpha RGBA8888, row-major.
typedef MipPixels = ({int width, int height, Uint8List pixels});

/// Uploads an image as a mipmapped GPU texture, the chain built with lookup
/// tables (PORTFOLIO-8).
///
/// `Texture2D.fromImage` builds the same chain, the same way: each level a
/// 2x2 box filter of the one above, colour averaged in linear light, normals
/// renormalised. It does it with `math.pow` twice per channel per texel,
/// fifteen calls for every colour texel of every level, on the main thread,
/// because the web has no isolates. At 4x CPU that was about 1.1 s for each
/// 1024² colour map and 0.8 s for each project card: 28 of the build's 30 s
/// of uploads, behind the one loading screen.
///
/// Here sRGB to linear is a 256-entry table, and linear back to sRGB is a
/// search over the 255 points where the rounded byte changes, so a texel
/// costs a few additions and comparisons. The bytes are the package's bytes;
/// the test holds them to that.
abstract final class GpuUpload {
  /// Reads [image] back, builds its mip chain and uploads it.
  ///
  /// Sampled trilinear and anisotropic, as `Texture2D` samples a mipmapped
  /// texture by default.
  static Future<TextureSource> image(
    ui.Image image, {
    TextureContent content = TextureContent.color,
  }) async {
    final bytes = await image.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    );
    if (bytes == null) {
      throw Exception('Failed to read RGBA data from image.');
    }
    final width = image.width;
    final height = image.height;
    final levels = mipChain(
      bytes.buffer.asUint8List(),
      width,
      height,
      content,
      maxLevels: gpu.Texture.fullMipCount(width, height),
    );
    final texture = gpu.gpuContext.createTexture(
      gpu.StorageMode.hostVisible,
      width,
      height,
      mipLevelCount: levels.length,
    );
    for (var i = 0; i < levels.length; i++) {
      texture.overwrite(ByteData.sublistView(levels[i].pixels), mipLevel: i);
    }
    return GpuTextureSource(texture);
  }

  /// The mip chain for [pixels], base level first, at most [maxLevels] long.
  ///
  /// The GPU allocator takes no more than `gpu.Texture.fullMipCount` levels
  /// (`floor(log2(min(w, h)))` on the web), which is shorter than the full
  /// chain; the package builds the full chain and drops the rest, this stops
  /// where the allocator does.
  @visibleForTesting
  static List<MipPixels> mipChain(
    Uint8List pixels,
    int width,
    int height,
    TextureContent content, {
    int? maxLevels,
  }) {
    final levels = <MipPixels>[(width: width, height: height, pixels: pixels)];
    var w = width;
    var h = height;
    var src = pixels;
    while ((w > 1 || h > 1) &&
        (maxLevels == null || levels.length < maxLevels)) {
      final nw = math.max(1, w >> 1);
      final nh = math.max(1, h >> 1);
      final dst = switch (content) {
        TextureContent.color => _colour(src, w, h, nw, nh),
        TextureContent.data => _data(src, w, h, nw, nh),
        TextureContent.normal => _normal(src, w, h, nw, nh),
      };
      levels.add((width: nw, height: nh, pixels: dst));
      src = dst;
      w = nw;
      h = nh;
    }
    return levels;
  }

  // Each destination texel is the 2x2 block at twice its position in the
  // source, clamped at the far edges: the package's sampling pattern.

  static Uint8List _colour(Uint8List src, int sw, int sh, int dw, int dh) {
    final dst = Uint8List(dw * dh * 4);
    final toLinear = _toLinear;
    for (var y = 0; y < dh; y++) {
      final y0 = math.min(y * 2, sh - 1);
      final y1 = math.min(y0 + 1, sh - 1);
      for (var x = 0; x < dw; x++) {
        final x0 = math.min(x * 2, sw - 1);
        final x1 = math.min(x0 + 1, sw - 1);
        final a = (y0 * sw + x0) * 4;
        final b = (y0 * sw + x1) * 4;
        final c = (y1 * sw + x0) * 4;
        final d = (y1 * sw + x1) * 4;
        final o = (y * dw + x) * 4;
        for (var ch = 0; ch < 3; ch++) {
          final avg = (toLinear[src[a + ch]] +
                  toLinear[src[b + ch]] +
                  toLinear[src[c + ch]] +
                  toLinear[src[d + ch]]) *
              0.25;
          dst[o + ch] = _toSrgb(avg);
        }
        dst[o + 3] =
            ((src[a + 3] + src[b + 3] + src[c + 3] + src[d + 3]) + 2) ~/ 4;
      }
    }
    return dst;
  }

  static Uint8List _data(Uint8List src, int sw, int sh, int dw, int dh) {
    final dst = Uint8List(dw * dh * 4);
    for (var y = 0; y < dh; y++) {
      final y0 = math.min(y * 2, sh - 1);
      final y1 = math.min(y0 + 1, sh - 1);
      for (var x = 0; x < dw; x++) {
        final x0 = math.min(x * 2, sw - 1);
        final x1 = math.min(x0 + 1, sw - 1);
        final a = (y0 * sw + x0) * 4;
        final b = (y0 * sw + x1) * 4;
        final c = (y1 * sw + x0) * 4;
        final d = (y1 * sw + x1) * 4;
        final o = (y * dw + x) * 4;
        for (var ch = 0; ch < 4; ch++) {
          dst[o + ch] =
              ((src[a + ch] + src[b + ch] + src[c + ch] + src[d + ch]) + 2) ~/
                  4;
        }
      }
    }
    return dst;
  }

  static Uint8List _normal(Uint8List src, int sw, int sh, int dw, int dh) {
    final dst = Uint8List(dw * dh * 4);
    for (var y = 0; y < dh; y++) {
      final y0 = math.min(y * 2, sh - 1);
      final y1 = math.min(y0 + 1, sh - 1);
      for (var x = 0; x < dw; x++) {
        final x0 = math.min(x * 2, sw - 1);
        final x1 = math.min(x0 + 1, sw - 1);
        final a = (y0 * sw + x0) * 4;
        final b = (y0 * sw + x1) * 4;
        final c = (y1 * sw + x0) * 4;
        final d = (y1 * sw + x1) * 4;
        final o = (y * dw + x) * 4;
        // The package's sums, in its order (a, b, c, d), so the floats round
        // the same way; only the list it allocated per texel is gone.
        var nx = 0.0, ny = 0.0, nz = 0.0;
        nx += src[a] / 127.5 - 1.0;
        ny += src[a + 1] / 127.5 - 1.0;
        nz += src[a + 2] / 127.5 - 1.0;
        nx += src[b] / 127.5 - 1.0;
        ny += src[b + 1] / 127.5 - 1.0;
        nz += src[b + 2] / 127.5 - 1.0;
        nx += src[c] / 127.5 - 1.0;
        ny += src[c + 1] / 127.5 - 1.0;
        nz += src[c + 2] / 127.5 - 1.0;
        nx += src[d] / 127.5 - 1.0;
        ny += src[d + 1] / 127.5 - 1.0;
        nz += src[d + 2] / 127.5 - 1.0;
        final len = math.sqrt(nx * nx + ny * ny + nz * nz);
        if (len > 1e-6) {
          nx /= len;
          ny /= len;
          nz /= len;
        } else {
          nx = 0.0;
          ny = 0.0;
          nz = 1.0;
        }
        dst[o] = _unit(nx);
        dst[o + 1] = _unit(ny);
        dst[o + 2] = _unit(nz);
        dst[o + 3] = 255;
      }
    }
    return dst;
  }

  static int _unit(double v) => ((v + 1.0) * 127.5).round().clamp(0, 255);

  /// sRGB byte to linear, the package's formula, once per byte.
  static final Float64List _toLinear = Float64List.fromList(
    List<double>.generate(256, (byte) {
      final c = byte / 255.0;
      return c <= 0.04045
          ? c / 12.92
          : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
    }),
  );

  /// The package's linear-to-sRGB byte, computed directly. Only used to
  /// find [_steps]; the per-texel path never calls it.
  static int _srgbByte(double linear) {
    final c = linear <= 0.0031308
        ? linear * 12.92
        : 1.055 * math.pow(linear, 1 / 2.4).toDouble() - 0.055;
    return (c * 255.0).round().clamp(0, 255);
  }

  /// `_steps[k - 1]` is the smallest linear value whose sRGB byte is at
  /// least k, for k in 1..255, found by bisecting [_srgbByte] itself, so the
  /// table agrees with the formula wherever the formula is monotonic.
  static final Float64List _steps = () {
    final steps = Float64List(255);
    for (var k = 1; k <= 255; k++) {
      var lo = 0.0;
      var hi = 1.0;
      for (var i = 0; i < 64; i++) {
        final mid = (lo + hi) / 2;
        if (_srgbByte(mid) >= k) {
          hi = mid;
        } else {
          lo = mid;
        }
      }
      steps[k - 1] = hi;
    }
    return steps;
  }();

  /// How many of [_steps] [linear] has reached: its sRGB byte.
  static int _toSrgb(double linear) {
    final steps = _steps;
    var lo = 0;
    var hi = 255;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (linear >= steps[mid]) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }
}
