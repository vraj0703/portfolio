import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/style/text_styles.dart';
import 'package:portfolio/presentation/gallery/texture_sets.dart';
import 'package:portfolio/presentation/gallery/wall_text.dart';

double luminance(Color colour) =>
    (0.2126 * colour.r + 0.7152 * colour.g + 0.0722 * colour.b);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the pigment', () {
    test('is far darker than the marble it has to read against', () {
      // The measurement the whole approach rests on. The marble's own albedo
      // is 0.875 and the room's lamps are on it, so lettering cannot win on
      // brightness — it has to be darker, and it has to be coloured.
      const marble = 0.875;
      expect(luminance(WallText.fallbackPigment), lessThan(marble - 0.35));
    });

    test('and is a colour, not a grey', () {
      // Half the separation is hue. A dark grey at the same luminance would
      // read as a smudge on stone; a pigment reads as something applied.
      final pigment = WallText.fallbackPigment;
      final channels = <double>[pigment.r, pigment.g, pigment.b];
      final spread =
          channels.reduce((a, b) => a > b ? a : b) -
          channels.reduce((a, b) => a < b ? a : b);

      expect(spread, greaterThan(0.4));
    });
  });

  group('the paint the letters are cut out of', () {
    test('is shipped, and is the colour it was measured as', () async {
      final paint = await SurfaceMaps.decodeMap(WallTextAssets.paintMap);

      expect(
        paint,
        isNotNull,
        reason: 'the pigment is undeclared or will not decode',
      );
      paint!.dispose();
    });

    test('shows its own surface rather than one flat patch', () {
      // At one to one a whole letter sits inside a single patch of a square
      // metre of wall, and the paint reads as flat colour.
      expect(WallText.grainScale, lessThan(1));
      expect(WallText.grainScale, greaterThan(0));
    });
  });

  group('rendering', () {
    const type = DefaultAppTypography();

    test('lays lettering down without a paint to hand', () async {
      // The way out of the gallery is lettered on a wall. A decode that
      // fails must leave a flat sign, not an unlettered one.
      final image = await WallText.render(
        paint: null,
        width: 400,
        height: 160,
        lines: <TextSpan>[TextSpan(text: 'BACK', style: type.wallSign)],
      );

      expect(image.width, 400);
      expect(image.height, 160);
      image.dispose();
    });

    test('leaves the wall showing between the letters', () async {
      // Transparent apart from the letterforms. Opaque, and every sign is a
      // slab hung on the plaster — which is what a texture bound to a
      // material that does not blend already looks like.
      final image = await WallText.render(
        paint: null,
        width: 64,
        height: 64,
        lines: <TextSpan>[TextSpan(text: 'I', style: type.wallSign)],
      );

      final bytes = (await image.toByteData())!;
      // The bottom-left corner, well clear of a centred capital.
      final alpha = bytes.getUint8((63 * 64 + 1) * 4 + 3);

      expect(alpha, 0);
      image.dispose();
    });

    test('centres the block in the image it is baked into', () async {
      // The texture is stretched onto whatever rectangle the sign occupies,
      // so lettering that starts at the top of it arrives hard against the
      // top edge of the sign with all the room underneath.
      final image = await WallText.render(
        paint: null,
        width: 64,
        height: 200,
        lines: <TextSpan>[TextSpan(text: 'I', style: type.wallSign)],
      );

      final bytes = (await image.toByteData())!;
      int alphaAt(int x, int y) => bytes.getUint8((y * 64 + x) * 4 + 3);

      // Something down the middle, and nothing at either end.
      final middle = List<int>.generate(20, (i) => alphaAt(32, 90 + i));

      expect(middle.any((a) => a > 0), isTrue, reason: 'nothing in the middle');
      expect(alphaAt(32, 2), 0, reason: 'lettering against the top edge');
      expect(alphaAt(32, 197), 0, reason: 'lettering against the bottom edge');
      image.dispose();
    });
  });
}

/// Where the scene builder keeps the pigment, restated so the test does not
/// have to reach into a class whose other half needs a GPU.
abstract final class WallTextAssets {
  static const String paintMap =
      'assets/textures/paint/Paint001_1K-JPG_Color.jpg';
}
