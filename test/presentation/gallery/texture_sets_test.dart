import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/presentation/gallery/texture_sets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sets = <String, TextureSet>{
    'floor': GallerySurfaces.floor,
    'wall': GallerySurfaces.wall,
    'ceiling': GallerySurfaces.ceiling,
    'keyboardBase': GallerySurfaces.keyboardBase,
    'keys1': GallerySurfaces.keyRows[0],
    'keys2': GallerySurfaces.keyRows[1],
    'keys3': GallerySurfaces.keyRows[2],
  };

  group('every declared map is in the bundle and decodes', () {
    sets.forEach((name, set) {
      test(name, () async {
        for (final asset in <String?>[
          set.colour,
          set.roughMetal,
          set.normal,
          set.occlusion,
        ].nonNulls) {
          final image = await SurfaceMaps.decodeMap(asset);
          addTearDown(() => image?.dispose());

          expect(
            image,
            isNotNull,
            reason: '$asset is named by the set but did not decode — either '
                'it is missing from pubspec.yaml, or it is a format Flutter '
                'has no codec for (an .exr will fail here silently)',
          );
          // A 4K map is 67MB decoded and the room needs eight of them.
          // Downsampling has to happen *at* decode; doing it afterwards
          // means the full size existed in memory first.
          expect(image!.width, SurfaceMaps.resolution);
        }
      });
    });
  });

  group('packed roughness and metal maps are up to date with their sources', () {
    // Packed once by tool/pack_rough_metal.py, not in the browser
    // (PORTFOLIO-8). Read straight from disk, so the sources need not ship.
    Future<List<int>> pixels(String path) async {
      final codec = await ui.instantiateImageCodec(
        File(path).readAsBytesSync(),
      );
      final image = (await codec.getNextFrame()).image;
      codec.dispose();
      final data = await image.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );
      image.dispose();
      return data!.buffer.asUint8List();
    }

    sets.forEach((name, set) {
      final from = set.packedFrom;
      if (from == null) return;
      test(name, () async {
        final packed = await pixels(set.roughMetal);
        final rough = await pixels(from.roughness);
        final metal = from.metalness == null
            ? null
            : await pixels(from.metalness!);
        expect(packed.length, rough.length, reason: 'not the source size');

        final metallicByte = (from.metallic * 255).round();
        var worst = 0;
        for (var i = 0; i < packed.length; i += 4) {
          // Green is the roughness, blue the metalness: the two channels the
          // shader reads. A pixel off by more than a rounding step means the
          // file was not regenerated after its source changed.
          final g = (packed[i + 1] - rough[i]).abs();
          final b = (packed[i + 2] - (metal?[i] ?? metallicByte)).abs();
          worst = [worst, g, b].reduce((x, y) => x > y ? x : y);
          expect(packed[i + 3], 255);
        }
        expect(
          worst,
          lessThanOrEqualTo(2),
          reason:
              '${set.roughMetal} is stale: run python tool/pack_rough_metal.py',
        );
      });
    });
  });

  test('a dielectric loads its grey map as it is and zeroes the metal', () {
    // Every channel of a grey map holds roughness, blue included, so the
    // material's factor has to be zero or the surface turns metal where it
    // is rough.
    for (final set in <TextureSet>[
      GallerySurfaces.floor,
      GallerySurfaces.wall,
      GallerySurfaces.ceiling,
      GallerySurfaces.frame,
      GallerySurfaces.testimonialFrame,
    ]) {
      expect(set.packedFrom, isNull, reason: set.roughMetal);
      expect(set.metallic, 0, reason: set.roughMetal);
    }
  });

  test('a packed map carries its own metal at full factor', () {
    for (final set in <TextureSet>[
      GallerySurfaces.keyboardBase,
      ...GallerySurfaces.keyRows,
    ]) {
      expect(set.packedFrom, isNotNull, reason: set.roughMetal);
      expect(set.metallic, 1, reason: set.roughMetal);
    }
  });

  group('every surface has relief', () {
    // This did not hold when the sets came from mixed sources: two of them
    // shipped their normals as OpenEXR, which Flutter has no codec for, so
    // those surfaces were colour and roughness only. Worth asserting now
    // that it does — a set swapped for one without a decodable normal map
    // would otherwise go flat without anything failing.
    sets.forEach((name, set) {
      test(name, () => expect(set.normal, isNotNull));
    });
  });

  group('the OpenGL normal variant is the one used', () {
    // Both conventions ship side by side. The DirectX variant has green
    // inverted, so it lights every bump from the wrong side — which reads as
    // the surface being subtly inside-out rather than as an obvious error,
    // and is close to impossible to spot once the room is lit.
    sets.forEach((name, set) {
      test(name, () => expect(set.normal, isNot(contains('NormalDX'))));
    });
  });

  test('a set knows how many files it is made of', () {
    // The loading bar divides by this before the work starts. Get it wrong
    // and the bar either stalls short of the mark or overshoots it — and
    // nothing else in the build would notice.
    sets.forEach((name, set) {
      final declared = <String?>[
        set.colour,
        set.roughMetal,
        set.normal,
        set.occlusion,
      ].nonNulls.length;

      expect(set.mapCount, declared, reason: name);
      // Two steps per bound file: it is decoded, then uploaded. Counting only
      // the decodes is what left the bar silent through every upload.
      expect(set.stepCount, declared * 2, reason: name);
    });
  });
}