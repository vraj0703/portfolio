import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/style/text_styles.dart';
import 'package:portfolio/presentation/gallery/wall_text.dart';

double luminance(Color colour) =>
    0.2126 * colour.r + 0.7152 * colour.g + 0.0722 * colour.b;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const type = DefaultAppTypography();

  group('the light', () {
    test('falls from above, so the letters read as cut and not raised', () {
      // The single easiest thing to get backwards. The eye infers a surface
      // entirely from which of its two edges is lit — invert this and the
      // identical texture reads as lettering standing proud of the wall.
      expect(WallText.lightFrom.dy, lessThan(0));
    });

    test('and both walls of the groove face opposite ways', () {
      final unit = WallText.normalise(WallText.lightFrom);
      expect(unit.distance, closeTo(1, 1e-9));

      // Same vector, opposite signs. Moving the lamp cannot leave the dark
      // wall and the lit one on the same side of the letter.
      final dark = -unit * WallText.depth;
      final lit = unit * WallText.depth;
      expect(dark.dx.sign, isNot(lit.dx.sign));
      expect(dark.dy.sign, isNot(lit.dy.sign));
    });

    test('a direction of no length does not divide by zero', () {
      expect(WallText.normalise(Offset.zero), Offset.zero);
    });
  });

  group('the depth is measured from the type, not in pixels', () {
    test('so a small line is cut as shallowly as a large one is deep', () {
      // The four signs bake to textures of very different heights — the far
      // wall's is nearly six hundred pixels and the hall's instruction under
      // a hundred and sixty. A fixed offset is a deep cut on one and a
      // smudge on the other.
      expect(WallText.depth, greaterThan(0));
      expect(WallText.depth, lessThan(0.2));
    });

    test('and a wall stays an edge rather than becoming a wash', () {
      // Softened as wide as it is, a wall stops being a line and spreads
      // across the letter — which is a fill by another route, and a fill is
      // what made this read as printed.
      expect(WallText.wallSoftness, lessThan(0.5));
      expect(WallText.wallSoftness, greaterThan(0));
    });
  });

  group('the groove is read by its dark side', () {
    test('so the shadow carries more than the light', () {
      // An equally bright highlight reads as chrome rather than as stone.
      expect(WallText.shadowAlpha, greaterThan(WallText.lightAlpha));
    });

    test('and the two walls are genuinely dark and genuinely light', () {
      expect(luminance(WallText.cutShadow), lessThan(0.15));
      expect(luminance(WallText.cutLight), greaterThan(0.9));
    });

    test('and the lit wall answers the shadow rather than matching it', () {
      // The shade carries the depth. A highlight as strong as it reads as
      // polished metal standing proud of the wall — which is the reading
      // this whole construction exists to rule out.
      expect(WallText.shadowAlpha, greaterThan(0.7));
      expect(WallText.lightAlpha, greaterThan(0.2));
      expect(WallText.lightAlpha, lessThan(WallText.shadowAlpha * 0.7));
    });

    test('and the lit wall is the narrower of the two', () {
      // In a real cut the lit wall is partly in its own shade. Two walls of
      // equal width read as a bevel rather than a channel.
      expect(WallText.lightShare, lessThan(1));
      expect(WallText.lightShare, greaterThan(0));
    });
  });

  group('rendering', () {
    test('bakes at the size it is asked for', () async {
      final image = await WallText.render(
        width: 400,
        height: 160,
        lines: <TextSpan>[TextSpan(text: 'BACK', style: type.wallSign)],
      );

      expect(image.width, 400);
      expect(image.height, 160);
      image.dispose();
    });

    test('leaves the wall showing between the letters', () async {
      // Nearly all of this texture is nothing. Opaque, and every sign is a
      // slab hung on the plaster.
      final image = await WallText.render(
        width: 600,
        height: 400,
        lines: <TextSpan>[TextSpan(text: 'I', style: type.wallSign)],
      );

      final bytes = (await image.toByteData())!;
      expect(bytes.getUint8((4 * 600 + 4) * 4 + 3), 0);
      image.dispose();
    });

    test('centres the block in the image it is baked into', () async {
      // The texture is stretched onto whatever rectangle the sign occupies,
      // so lettering that starts at the top of it arrives hard against the
      // top edge of the sign with all the room underneath.
      // Type sized to the canvas rather than the canvas to the type: this
      // is a test about where the block lands, and a sign's own size would
      // overflow a probe small enough to scan cheaply.
      final image = await WallText.render(
        width: 64,
        height: 200,
        lines: <TextSpan>[
          TextSpan(text: 'I', style: type.wallSign.copyWith(fontSize: 40)),
        ],
      );

      final bytes = (await image.toByteData())!;
      int alphaAt(int x, int y) => bytes.getUint8((y * 64 + x) * 4 + 3);

      /// Whether anything at all is painted across row [y].
      ///
      /// A whole row rather than one column: the middle of a stroke is empty
      /// now — only its two edges are painted — so a probe down the centre
      /// line of the glyph finds nothing precisely when the engraving is
      /// working.
      bool inkOn(int y) {
        for (var x = 0; x < 64; x++) {
          if (alphaAt(x, y) > 0) return true;
        }
        return false;
      }

      expect(
        List<int>.generate(20, (i) => 90 + i).any(inkOn),
        isTrue,
        reason: 'nothing in the middle',
      );
      expect(inkOn(1), isFalse, reason: 'lettering against the top edge');
      expect(inkOn(198), isFalse, reason: 'against the bottom edge');
      image.dispose();
    });

    test('cuts a dark wall and a lit one into the same stroke', () async {
      // The whole effect in one assertion. A groove has both; a drop shadow
      // has only the dark one, and a flat letter has neither.
      final image = await WallText.render(
        width: 200,
        height: 200,
        lines: <TextSpan>[
          TextSpan(text: 'I', style: type.wallSign.copyWith(fontSize: 120)),
        ],
      );

      final bytes = (await image.toByteData())!;

      // `toByteData` hands back *premultiplied* channels, so a white wall at
      // half alpha arrives as mid-grey. Divided back out, this is what was
      // painted rather than what it composites to over nothing.
      double luminanceAt(int x, int y) {
        final i = (y * 200 + x) * 4;
        final alpha = bytes.getUint8(i + 3) / 255;
        if (alpha == 0) return -1;
        return luminance(
          Color.from(
            alpha: 1,
            red: bytes.getUint8(i) / 255 / alpha,
            green: bytes.getUint8(i + 1) / 255 / alpha,
            blue: bytes.getUint8(i + 2) / 255 / alpha,
          ),
        );
      }

      final row = <double>[
        for (var x = 0; x < 200; x++)
          if (luminanceAt(x, 100) >= 0) luminanceAt(x, 100),
      ];

      expect(row, isNotEmpty, reason: 'nothing was drawn');
      expect(
        row.reduce((a, b) => a > b ? a : b),
        greaterThan(0.7),
        reason: 'no lit wall — the cut has only one side',
      );
      expect(
        row.reduce((a, b) => a < b ? a : b),
        lessThan(0.3),
        reason: 'no dark wall — the letters are drawn, not cut',
      );
      image.dispose();
    });

    test('casts no shadow onto the wall beside a letter', () async {
      // The fault this was written for. A blur spreads in every direction,
      // so softening each wall pushed it out past the letterform onto the
      // marble — a soft dark rim beside every letter, which is a drop shadow
      // by any other name. A shape with a shadow beside it is a shape *on* a
      // surface, not a hole in one, and that is what kept the lettering
      // reading as floating even once the walls were right.
      //
      // Measured as the alpha immediately outside a stroke: an engraving
      // stops dead at its own edge.
      final image = await WallText.render(
        width: 300,
        height: 300,
        lines: <TextSpan>[
          TextSpan(text: 'I', style: type.wallSign.copyWith(fontSize: 200)),
        ],
      );

      final bytes = (await image.toByteData())!;
      int alphaAt(int x, int y) => bytes.getUint8((y * 300 + x) * 4 + 3);

      // Find the stroke on the row through the middle, then step off it.
      var left = -1;
      var right = -1;
      for (var x = 0; x < 300; x++) {
        if (alphaAt(x, 150) > 0) {
          if (left < 0) left = x;
          right = x;
        }
      }

      expect(left, greaterThan(0), reason: 'nothing was drawn');

      // Four pixels clear of the glyph on either side. Any ink here is the
      // blur having escaped the letterform.
      expect(alphaAt(left - 4, 150), 0, reason: 'shadow to the left');
      expect(alphaAt(right + 4, 150), 0, reason: 'shadow to the right');
      image.dispose();
    });

    test('lays gold in the opening', () async {
      // Two edges alone leave the shape ambiguous — a rim of light one side
      // and shade the other describes a ridge as well as a groove, and the
      // eye picks whichever it likes. Something that is plainly not marble
      // in the opening settles it, and is the only real contrast the
      // lettering has.
      final image = await WallText.render(
        width: 300,
        height: 300,
        lines: <TextSpan>[
          TextSpan(text: 'H', style: type.wallSign.copyWith(fontSize: 200)),
        ],
      );

      final bytes = (await image.toByteData())!;
      var gold = 0;
      for (var i = 0; i < 300 * 300; i++) {
        if (bytes.getUint8(i * 4 + 3) == 255) gold++;
      }

      expect(gold, greaterThan(0), reason: 'the opening is empty');
      image.dispose();
    });

    test('and the gold is darker than the marble, and warm', () {
      const marble = 0.875;
      final gold = WallText.inlay;

      expect(luminance(gold), lessThan(marble * 0.6));
      expect(gold.r, greaterThan(gold.b), reason: 'not warm');
    });
  });
}
