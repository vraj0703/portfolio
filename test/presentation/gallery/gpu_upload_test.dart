import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_scene/scene.dart' show TextureContent;
// The package's own generator: the reference GpuUpload has to match.
// ignore: implementation_imports
import 'package:flutter_scene/src/texture/mipmap.dart' as reference;
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/presentation/gallery/gpu_upload.dart';

/// Every level of [ours] has the same size and bytes as [theirs]'s.
void expectSameChain(
  List<MipPixels> ours,
  List<reference.MipLevel> theirs,
  String what,
) {
  expect(ours.length, lessThanOrEqualTo(theirs.length), reason: what);
  for (var i = 0; i < ours.length; i++) {
    final a = ours[i];
    final b = theirs[i];
    expect((a.width, a.height), (b.width, b.height), reason: '$what level $i');
    var differ = 0;
    for (var p = 0; p < a.pixels.length; p++) {
      if (a.pixels[p] != b.pixels[p]) differ++;
    }
    expect(differ, 0, reason: '$what level $i: $differ bytes differ');
  }
}

Future<Uint8List> decode(String path) async {
  final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
  final image = (await codec.getNextFrame()).image;
  codec.dispose();
  final data = await image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  image.dispose();
  return data!.buffer.asUint8List();
}

void main() {
  // PORTFOLIO-8 (b): the chain is built here instead of by Texture2D, which
  // spent about 28 s of a 4x-CPU build in math.pow. Same bytes, or it is a
  // visible change hiding inside a speed-up.
  group('the mip chain is the package\'s, byte for byte', () {
    final random = math.Random(8);
    Uint8List noise(int w, int h) =>
        Uint8List.fromList(List<int>.generate(w * h * 4, (_) => random.nextInt(256)));

    for (final content in TextureContent.values) {
      test('${content.name}, random pixels, square', () {
        final pixels = noise(64, 64);
        expectSameChain(
          GpuUpload.mipChain(pixels, 64, 64, content),
          reference.generateMipChain(pixels, 64, 64, content),
          content.name,
        );
      });

      test('${content.name}, random pixels, a card\'s odd shape', () {
        // Odd sizes take the clamped-edge path the 1024x736 cards and the
        // 3840x510 sign go through further down their chains.
        final pixels = noise(103, 37);
        expectSameChain(
          GpuUpload.mipChain(pixels, 103, 37, content),
          reference.generateMipChain(pixels, 103, 37, content),
          content.name,
        );
      });
    }

    test('every byte value survives the round trip through linear light', () {
      // Four equal texels average to themselves: sRGB to linear and back for
      // each of the 256 values, the step the lookup tables replace.
      final pixels = Uint8List(256 * 2 * 2 * 4);
      for (var v = 0; v < 256; v++) {
        for (final dy in [0, 1]) {
          for (final dx in [0, 1]) {
            final o = (dy * 512 + v * 2 + dx) * 4;
            pixels.fillRange(o, o + 4, v);
          }
        }
      }
      final ours = GpuUpload.mipChain(pixels, 512, 2, TextureContent.color, maxLevels: 2);
      final theirs = reference.generateMipChain(pixels, 512, 2, TextureContent.color);
      expectSameChain(ours, theirs, 'grey ramp');
      for (var v = 0; v < 256; v++) {
        expect(ours[1].pixels[v * 4], v, reason: 'byte $v');
      }
    });

    test('a real colour map', () async {
      final pixels = await decode(
        'assets/textures/floor/Tiles013_1K-JPG_Color.webp',
      );
      expectSameChain(
        GpuUpload.mipChain(pixels, 1024, 1024, TextureContent.color),
        reference.generateMipChain(pixels, 1024, 1024, TextureContent.color),
        'floor colour',
      );
    });

    test('a real normal map', () async {
      final pixels = await decode(
        'assets/textures/wall/Marble004_1K-JPG_NormalGL.webp',
      );
      expectSameChain(
        GpuUpload.mipChain(pixels, 1024, 1024, TextureContent.normal),
        reference.generateMipChain(pixels, 1024, 1024, TextureContent.normal),
        'wall normal',
      );
    });
  });

  test('the chain stops where the allocator does', () {
    // The web allocator takes floor(log2(min(1024, 736))) = 9 levels for a
    // project card; the package builds 11 and drops two.
    final pixels = Uint8List(1024 * 736 * 4);
    final chain = GpuUpload.mipChain(
      pixels,
      1024,
      736,
      TextureContent.color,
      maxLevels: 9,
    );
    expect(chain.length, 9);
    expect((chain.last.width, chain.last.height), (4, 2));
  });
}
