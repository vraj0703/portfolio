import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;

/// Lettering laid onto a wall in paint, rasterised once.
///
/// Not a `WidgetComponent`. A live widget surface re-rasterises on its update
/// policy whether or not anyone can see it, which put a capture inside the
/// render loop for text that never changes — and on the manual policy, which
/// avoids that cost, it never rasterises at all. Baking to an image once is
/// the same pipeline the room's other textures already use: it renders, it is
/// done after one frame, and it costs nothing thereafter.
///
/// The image is transparent apart from the letterforms, which only works if
/// the material it is bound to actually blends — see [wallMaterialNote].
///
/// ## Why paint, and not the two attempts before it
///
/// Lettering here has to read against marble whose own albedo is 0.875 —
/// brighter, once the room's lamps are on it, than any unlit ink can be. A
/// pale ink measured 0.908 against that, a contrast ratio of 1.04:1 where
/// text wants 4.5:1, and no weight or glow rescued it. Cutting the letters
/// into the stone worked because a groove carries its own two edges wherever
/// it is. Paint works for the same reason from the other direction: the
/// pigment is 0.409 and strongly coloured, so it separates from the wall in
/// value *and* in hue rather than competing with it in brightness.
abstract final class WallText {
  /// Why the material matters as much as the image.
  ///
  /// A transparent texture on an opaque material is not transparent: the
  /// renderer ignores alpha and the cleared background rasterises as solid
  /// black, so the sign arrives as a black slab with lettering on it. The
  /// texture is innocent; the material has to be told to blend.
  static const String wallMaterialNote =
      'bind to an UnlitMaterial with AlphaMode.blend';

  /// How much of the paint's own surface shows through one letter.
  ///
  /// The photograph is a square metre of painted wall and a sign is a few
  /// hundred pixels, so at one to one a whole letter would sit inside a
  /// single patch of it and the paint would read as flat colour. Scaled
  /// down, the brush and the roll come through at the size they would be on
  /// lettering this big.
  static const double grainScale = 0.4;

  /// The pigment, for when the photograph of it will not decode.
  ///
  /// Its own measured mean, so a sign lettered without the texture is the
  /// right colour and only misses the surface. The alternative is a room
  /// whose way out is unlettered, and a gallery you cannot leave is a worse
  /// failure than a flat sign.
  static const Color fallbackPigment = Color(0xFFDE4D1F);

  /// Lays [lines] down in [paint], centred in a [width] by [height] image.
  ///
  /// [gap] separates one line from the next. A measurement rather than a
  /// newline on the end of the copy: written into the string it is invisible
  /// to whoever rewrites the sentence, and the first thing they do is lose
  /// it.
  ///
  /// Centred vertically, which is not a nicety: the image is stretched onto
  /// whatever rectangle the sign occupies, so lettering that starts at the
  /// top of the texture arrives hard against the top edge of the sign with
  /// all the room underneath it. On a line of instruction two hundred pixels
  /// tall that reads as a mistake.
  static Future<ui.Image> render({
    required List<TextSpan> lines,
    required ui.Image? paint,
    required int width,
    required int height,
    double gap = 0,
  }) {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final brush = Paint();
    if (paint != null) {
      brush.shader = pigment(paint);
    } else {
      brush.color = fallbackPigment;
    }

    // Laid out first, then placed. The block's height is not known until
    // every line has been measured, and it is the block that gets centred —
    // centring each line on its own would stack them from the middle
    // outward.
    final painters = <TextPainter>[
      for (final line in lines)
        TextPainter(
          text: TextSpan(
            text: line.text,
            // `foreground` rather than `color`: the letters are a window
            // onto the paint, not a colour that happens to have come from it.
            style: line.style?.copyWith(foreground: brush),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: width.toDouble()),
    ];

    final block =
        painters.fold<double>(0, (sum, p) => sum + p.height) +
        gap * (painters.length - 1);
    var y = (height - block) / 2;

    for (var i = 0; i < painters.length; i++) {
      final painter = painters[i];
      painter.paint(canvas, ui.Offset((width - painter.width) / 2, y));
      y += painter.height;
      if (i < painters.length - 1) y += gap;
    }

    return recorder.endRecording().toImage(width, height);
  }

  /// The paint, as something a glyph can be filled with.
  ///
  /// Tiled, because the sign is wider than the photograph is once it has
  /// been scaled to a believable grain — and repeated rather than clamped,
  /// which would smear the edge pixel across everything past the first tile.
  static ui.ImageShader pigment(ui.Image paint) => ui.ImageShader(
    paint,
    ui.TileMode.repeated,
    ui.TileMode.repeated,
    (Matrix4.identity()..scaleByDouble(grainScale, grainScale, 1, 1)).storage,
  );
}
