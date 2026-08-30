import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:portfolio/domain/style/text_styles.dart';

/// Lettering cut into a wall, rasterised once.
///
/// Not a `WidgetComponent`. A live widget surface re-rasterises on its update
/// policy whether or not anyone can see it, which put a capture inside the
/// render loop for text that never changes — and on the manual policy, which
/// avoids that cost, it never rasterises at all. Baking to an image once is
/// the same pipeline the room's other textures already use: it renders, it is
/// done after one frame, and it costs nothing thereafter.
///
/// The image is transparent apart from the two edges of the cut, which only
/// works if the material it is bound to actually blends — see
/// [wallMaterialNote].
abstract final class WallText {
  /// Why the material matters as much as the image.
  ///
  /// A transparent texture on an opaque material is not transparent: the
  /// renderer ignores alpha and the cleared background rasterises as solid
  /// black, so the sign arrives as a black slab with lettering on it. The
  /// texture is innocent; the material has to be told to blend.
  static const String wallMaterialNote =
      'bind to an UnlitMaterial with AlphaMode.blend';

  /// How far the light falls from, in pixels of the baked texture.
  ///
  /// Above and a little to the left, which is where the room's own lamps
  /// are. Getting this the wrong way round does not read as a mistake — it
  /// reads as lettering standing *proud* of the wall instead of cut into it,
  /// because the eye infers the direction of a surface entirely from which
  /// of its two edges is lit.
  static const Offset lightFrom = Offset(-3, -4);

  /// How wide the cut is.
  ///
  /// The offset between the two edges is the groove's width as the eye reads
  /// it. Too small and the letter looks printed; too large and it separates
  /// into two overlapping words in different colours.
  static const double cutWidth = 3.4;

  /// How soft each edge of the cut is.
  ///
  /// A carved edge is not a knife edge — the stone breaks away slightly, and
  /// a completely crisp shadow reads as a drop shadow under a sticker.
  static const double edgeSoftness = 2.2;

  /// How far the shadow inside the groove spreads back over the stone.
  ///
  /// Small. This is ambient occlusion in the cut, not a glow: it darkens the
  /// stone immediately around each letter, which is what gives the lettering
  /// contrast on a wall brighter than any ink could be.
  static const double occlusionRadius = 7;

  /// How dark that occlusion goes.
  static const double occlusionAlpha = 0.5;

  static Future<ui.Image> render({
    required List<TextSpan> lines,
    required int width,
    required int height,
    double rulePosition = 0,
    double ruleWidth = 0,
  }) {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    /// Lays the lines down once, in [colour], displaced by [shift].
    void paintLines({
      required Color colour,
      required Offset shift,
      double blur = 0,
    }) {
      var y = 0.0;
      for (final line in lines) {
        final paint = Paint()..color = colour;
        if (blur > 0) {
          paint.maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, blur);
        }

        final painter = TextPainter(
          text: TextSpan(
            text: line.text,
            style: line.style?.copyWith(foreground: paint),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: width.toDouble());

        painter.paint(
          canvas,
          ui.Offset((width - painter.width) / 2, y) + shift,
        );
        y += painter.height;
      }
    }

    // The order is the physics, and none of it is interchangeable.
    //
    // First the stone around the letter darkens, because a groove traps
    // light. Then the far wall of the cut — the side the light cannot reach
    // — and last the near wall, which it strikes. The middle is left
    // untouched: the bottom of the groove is the same marble as the wall,
    // and painting anything there is what turns a carving back into a
    // printed word.
    final unit = _normalise(lightFrom);

    paintLines(
      colour: DefaultAppTypography.wallCutShadow.withValues(
        alpha: occlusionAlpha,
      ),
      shift: Offset.zero,
      blur: occlusionRadius,
    );
    paintLines(
      colour: DefaultAppTypography.wallCutShadow,
      shift: unit * cutWidth,
      blur: edgeSoftness,
    );
    paintLines(
      colour: DefaultAppTypography.wallCutLight,
      shift: -unit * cutWidth,
      blur: edgeSoftness,
    );

    if (ruleWidth > 0) {
      _cutRule(canvas, width, rulePosition, ruleWidth, unit);
    }

    return recorder.endRecording().toImage(width, height);
  }

  /// The line under a sign, cut the same way the lettering is.
  static void _cutRule(
    ui.Canvas canvas,
    int width,
    double top,
    double ruleWidth,
    Offset unit,
  ) {
    final rule = ui.Rect.fromLTWH((width - ruleWidth) / 2, top, ruleWidth, 3);

    void stroke(Color colour, Offset shift, double blur) {
      canvas.drawRect(
        rule.shift(shift),
        ui.Paint()
          ..color = colour
          ..maskFilter = blur > 0
              ? ui.MaskFilter.blur(ui.BlurStyle.normal, blur)
              : null,
      );
    }

    stroke(
      DefaultAppTypography.wallCutShadow.withValues(alpha: occlusionAlpha),
      Offset.zero,
      occlusionRadius,
    );
    stroke(DefaultAppTypography.wallCutShadow, unit * cutWidth, edgeSoftness);
    stroke(DefaultAppTypography.wallCutLight, -unit * cutWidth, edgeSoftness);
  }

  /// [lightFrom] as a direction of length one.
  ///
  /// Separate and pure because it is the part with a rule worth checking: the
  /// two edges have to be displaced by the same distance in exactly opposite
  /// directions, or the cut comes out wider on one side than the other and
  /// the letter reads as double-struck rather than carved.
  static Offset normalise(Offset direction) => _normalise(direction);

  static Offset _normalise(Offset direction) {
    final length = direction.distance;
    return length < 1e-6 ? Offset.zero : direction / length;
  }
}
