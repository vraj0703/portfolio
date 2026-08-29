import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Text rasterised once, for painting onto a wall.
///
/// Not a `WidgetComponent`. A live widget surface re-rasterises on its update
/// policy whether or not anyone can see it, which put a capture inside the
/// render loop for text that never changes — and on the manual policy, which
/// avoids that cost, it never rasterises at all. Baking to an image once is
/// the same pipeline the room's other textures already use: it renders, it is
/// done after one frame, and it costs nothing thereafter.
///
/// The image is transparent apart from the lettering, which only works if the
/// material it is bound to actually blends — see [wallMaterialNote].
abstract final class WallText {
  /// Why the material matters as much as the image.
  ///
  /// A transparent texture on an opaque material is not transparent: the
  /// renderer ignores alpha and the cleared background rasterises as solid
  /// black, so the sign arrives as a black slab with lettering on it. The
  /// texture is innocent; the material has to be told to blend.
  static const String wallMaterialNote =
      'bind to an UnlitMaterial with AlphaMode.blend';

  /// How far the glow spreads beyond the letterforms, in pixels.
  ///
  /// Drawn as a blurred pass under the crisp one, which is what makes a
  /// stroke read as a light source rather than as a coloured shape. A single
  /// pass with a soft edge reads as blur; two passes read as neon.
  static const double glowRadius = 22;

  /// How many times the glow is laid down.
  ///
  /// One pass is too faint to survive the dim room; stacking a few builds
  /// the bloom up without needing a post-processing pass.
  static const int glowPasses = 3;

  static Future<ui.Image> render({
    required List<TextSpan> lines,
    required int width,
    required int height,
    double rulePosition = 0,
    Color ruleColour = const Color(0x00000000),
    double ruleWidth = 0,
    bool glow = true,
  }) {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    void paintLines({required bool blurred}) {
      var y = 0.0;
      for (final line in lines) {
        final span = blurred
            ? TextSpan(
                text: line.text,
                style: line.style?.copyWith(
                  foreground: Paint()
                    ..color = line.style?.color ?? const Color(0xFFFFFFFF)
                    ..maskFilter = const ui.MaskFilter.blur(
                      ui.BlurStyle.normal,
                      glowRadius,
                    ),
                ),
              )
            : line;

        final painter = TextPainter(
          text: span,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: width.toDouble());

        painter.paint(canvas, ui.Offset((width - painter.width) / 2, y));
        y += painter.height;
      }
    }

    if (glow) {
      for (var i = 0; i < glowPasses; i++) {
        paintLines(blurred: true);
      }
    }
    paintLines(blurred: false);

    if (ruleWidth > 0) {
      final rule = ui.Rect.fromLTWH(
        (width - ruleWidth) / 2,
        rulePosition,
        ruleWidth,
        2,
      );
      if (glow) {
        canvas.drawRect(
          rule,
          ui.Paint()
            ..color = ruleColour
            ..maskFilter = const ui.MaskFilter.blur(
              ui.BlurStyle.normal,
              glowRadius / 2,
            ),
        );
      }
      canvas.drawRect(rule, ui.Paint()..color = ruleColour);
    }

    return recorder.endRecording().toImage(width, height);
  }
}
