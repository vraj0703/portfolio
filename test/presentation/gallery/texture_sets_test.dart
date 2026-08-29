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
          set.roughness,
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

  test('roughness is packed into the channel the shader reads', () async {
    final image = await SurfaceMaps.packRoughness(GallerySurfaces.wall);
    addTearDown(() => image?.dispose());

    expect(image, isNotNull);
    final data = await image!.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    );
    final pixels = data!.buffer.asUint8List();
    final metallicByte = (GallerySurfaces.wall.metallic * 255).round();
    var sawRoughness = false;

    for (var i = 0; i < pixels.length; i += 4) {
      // Red is not read by the shader. These sets store roughness as a grey
      // image, so passing one through unpacked writes the value here and
      // nowhere else — leaving the surface uniformly glossy while looking
      // entirely correct in an image viewer.
      expect(pixels[i], 0);
      expect(pixels[i + 2], metallicByte);
      if (pixels[i + 1] != 0) sawRoughness = true;
    }

    expect(sawRoughness, isTrue, reason: 'a fully black map carries nothing');
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
        set.roughness,
        set.normal,
        set.occlusion,
      ].nonNulls.length;

      expect(set.mapCount, declared, reason: name);
      // Two steps per bound file: it is decoded, then uploaded. Counting only
      // the decodes is what left the bar silent through every upload.
      //
      // A metalness map adds one, not two: it is folded into the roughness
      // map's blue channel rather than uploaded on its own.
      expect(
        set.stepCount,
        declared * 2 + (set.metalness == null ? 0 : 1),
        reason: name,
      );
    });
  });
}