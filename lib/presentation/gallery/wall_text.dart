import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Lettering engraved into a wall, rasterised once.
///
/// Not a `WidgetComponent`. A live widget surface re-rasterises on its update
/// policy whether or not anyone can see it, which put a capture inside the
/// render loop for text that never changes — and on the manual policy, which
/// avoids that cost, it never rasterises at all. Baking to an image once is
/// the same pipeline the room's other textures already use: it renders, it is
/// done after one frame, and it costs nothing thereafter.
///
/// Most of the image is transparent, which works only if the material it is
/// bound to actually blends — an `UnlitMaterial` with `AlphaMode.blend`. A
/// transparent texture on an *opaque* material is not transparent: the
/// renderer ignores alpha and the cleared background rasterises as solid
/// black, so the sign arrives as a slab with lettering on it. The texture is
/// innocent; the material has to be told.
///
/// ## A groove with something in it
///
/// Three things are painted: a gold inlay filling the letterform, and the
/// pair of walls the groove makes — one dark, on the side the light cannot
/// reach, and one lit, opposite.
///
/// The inlay is not decoration. Two edges alone leave the shape *ambiguous*:
/// a rim of light on one side and shade on the other describes a groove and
/// a ridge equally well, and the eye picks whichever it likes — which is why
/// lettering that was constructed correctly still read as sitting on top of
/// the wall. Filling the opening with a material that is plainly not marble
/// settles it: whatever is in there is in a hole, because it is not the
/// surface. It is also the only contrast the lettering has, the marble being
/// brighter than any unlit mark can be.
///
/// The two walls are deliberately unequal. In a real cut the shadowed wall
/// is the broader of the two — the lit one is partly in its own shade — and
/// matching them reads as a bevel standing proud rather than a channel sunk
/// in.
///
/// Each is drawn as a **crescent** — the letterform with a copy of itself
/// subtracted, displaced by the width of the wall. What survives is a sliver
/// hugging one edge and nothing across the middle, which is where the wall of
/// a groove is not.
///
/// That construction is the whole of it, and getting it wrong is what made
/// the first attempt read as printed text floating on the surface. Offsetting
/// a blurred *copy* of the glyph and clipping it inside the letterform covers
/// most of the letter as soon as the offset approaches the stroke width: the
/// two walls overlap through the middle, average out to a flat grey, and what
/// is left is a filled letter with a soft shadow around it. Subtracting
/// instead of clipping is the difference between an edge and a fill.
///
/// ## Legibility
///
/// The marble's own albedo is 0.875 and the room's lamps are on it, while
/// this texture is unlit — so nothing here can win on brightness. [inlay]
/// wins on darkness and on hue instead: it is a little under half the
/// marble's value and strongly warm, which is the same argument the pigment
/// made before the lettering became a cut.
abstract final class WallText {
  /// Where the light falls from.
  ///
  /// Above and a little to the left, which is where the room's own lamps
  /// are. Getting this the wrong way round does not read as a mistake — it
  /// reads as lettering standing *proud* of the wall instead of cut into it,
  /// because the eye infers the direction of a surface entirely from which
  /// of its two edges is lit. Same texture, opposite meaning.
  static const Offset lightFrom = Offset(-0.7, -1);

  /// How wide each wall of the groove is, as a fraction of the type's size.
  ///
  /// The width of an *edge*, not an offset the letterform is displaced by.
  ///
  /// A fraction rather than pixels because the four signs bake to textures of
  /// very different heights — the far wall's is nearly six hundred pixels and
  /// the hall's instruction under a hundred and sixty — so a fixed offset is
  /// a deep cut on one and a smudge on the other.
  static const double depth = 0.045;

  /// How wide the lit wall is against the shadowed one.
  ///
  /// Narrower. The lit wall of a real cut is partly in its own shade, and
  /// two walls of equal width read as a bevel standing proud of the surface
  /// rather than a channel sunk into it.
  static const double lightShare = 0.6;

  /// How soft the edge of each wall is, against its own width.
  ///
  /// Well under one: stone breaks slightly at a cut but it is still an edge.
  /// Blurred as wide as it is, a wall stops being a line and becomes a wash
  /// across the letter — which is a fill by another route.
  static const double wallSoftness = 0.3;

  /// The two walls of the cut.
  ///
  /// The shadow is warm rather than neutral: it is gold in shade, not a
  /// black line drawn on gold.
  static const Color cutShadow = Color(0xFF1A1206);
  static const Color cutLight = Color(0xFFFFF6DF);

  /// How strongly each wall shows.
  ///
  /// The shadow carries the depth and the light only answers it. A highlight
  /// as strong as the shade reads as polished metal standing proud.
  static const double shadowAlpha = 0.85;
  static const double lightAlpha = 0.45;

  /// What sits in the groove.
  ///
  /// Gold laid into cut stone, which is what monumental lettering has always
  /// done and for the same reason: the stone is too pale to read against and
  /// the cut alone is too quiet. A little under half the marble's value and
  /// strongly warm, so it separates in brightness *and* in hue.
  static const Color inlay = Color(0xFFA9821F);

  /// Lays [lines] out and cuts them, centred in a [width] by [height] image.
  ///
  /// [gap] separates one line from the next. A measurement rather than a
  /// newline on the end of the copy: written into the string it is invisible
  /// to whoever rewrites the sentence, and the first thing they do is lose
  /// it.
  ///
  /// Centred vertically, which is not a nicety: the image is stretched onto
  /// whatever rectangle the sign occupies, so lettering that starts at the
  /// top of the texture arrives hard against the top edge of the sign with
  /// all the room underneath it.
  static Future<ui.Image> render({
    required List<TextSpan> lines,
    required int width,
    required int height,
    double gap = 0,
  }) {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final unit = _normalise(lightFrom);

    final placed = _place(lines: lines, width: width, height: height, gap: gap);

    for (final line in placed) {
      final edge = line.size * depth;
      final blur = edge * wallSoftness;

      // The inlay first, and the walls over it — the shade in a groove falls
      // on what is in the groove.
      _stroke(canvas, line, Paint()..color = inlay);

      _wall(
        canvas,
        line,
        colour: cutShadow.withValues(alpha: shadowAlpha),
        // Subtracting the copy displaced *away* from the light leaves the
        // sliver on the side the light cannot reach.
        away: -unit * edge,
        blur: blur,
      );
      _wall(
        canvas,
        line,
        colour: cutLight.withValues(alpha: lightAlpha),
        away: unit * edge * lightShare,
        blur: blur * lightShare,
      );
    }

    return recorder.endRecording().toImage(width, height);
  }

  /// One wall of the groove, along the side opposite [away].
  ///
  /// The letterform minus itself displaced, so what is left is a crescent
  /// hugging one edge rather than a copy of the glyph laid over it.
  static void _wall(
    ui.Canvas canvas,
    _PlacedLine line, {
    required Color colour,
    required Offset away,
    required double blur,
  }) {
    // Two layers, and the outer one is not optional.
    //
    // The blur belongs to the inner layer, applied as it composites, so it
    // softens the crescent *after* the subtraction has made one — blurring
    // the two copies first would leave nothing with an edge to soften.
    //
    // But a blur spreads a shape in every direction, including out past the
    // letterform onto the marble around it. That spill is a soft dark rim
    // sitting on the wall beside each letter, which is precisely what a drop
    // shadow is — and a shape with a shadow beside it is a shape *on* a
    // surface, not a hole in one. It is the whole reason the lettering still
    // read as floating after the crescents were right.
    //
    // So the outer layer trims the softened crescent back to the glyph. What
    // is left is a wall that fades toward the middle of the stroke and stops
    // dead at the letter's edge — which is what the wall of a cut does.
    canvas.saveLayer(null, Paint());

    canvas.saveLayer(
      null,
      Paint()
        ..imageFilter = blur > 0
            ? ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur)
            : null,
    );

    _stroke(canvas, line, Paint()..color = colour);

    // `dstOut` takes away what is already in the layer wherever this lands,
    // which leaves exactly the sliver the displaced copy does not cover.
    _stroke(
      canvas,
      line,
      Paint()
        ..color = const Color(0xFF000000)
        ..blendMode = BlendMode.dstOut,
      shift: away,
    );

    canvas.restore();

    // `dstIn` keeps what is in the outer layer only where the glyph is, so
    // nothing the blur pushed outside survives.
    _stroke(
      canvas,
      line,
      Paint()
        ..color = const Color(0xFF000000)
        ..blendMode = BlendMode.dstIn,
    );

    canvas.restore();
  }

  /// Each line, laid out and positioned.
  static List<_PlacedLine> _place({
    required List<TextSpan> lines,
    required int width,
    required int height,
    required double gap,
  }) {
    // Laid out first, then placed. The block's height is not known until
    // every line has been measured, and it is the block that gets centred —
    // centring each line on its own would stack them from the middle outward.
    final measured = <TextPainter>[
      for (final line in lines)
        TextPainter(
          text: line,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: width.toDouble()),
    ];

    final block =
        measured.fold<double>(0, (sum, p) => sum + p.height) +
        gap * (measured.length - 1);
    var y = (height - block) / 2;

    final placed = <_PlacedLine>[];
    for (var i = 0; i < measured.length; i++) {
      final painter = measured[i];
      placed.add(
        _PlacedLine(
          span: lines[i],
          at: ui.Offset((width - painter.width) / 2, y),
          maxWidth: width.toDouble(),
          size: lines[i].style?.fontSize ?? 16,
        ),
      );
      y += painter.height;
      if (i < measured.length - 1) y += gap;
    }
    return placed;
  }

  /// Draws one line once, with [brush], displaced by [shift].
  ///
  /// Re-laid on each pass rather than re-used, because the brush is part of
  /// the style a `TextPainter` is built from.
  static void _stroke(
    ui.Canvas canvas,
    _PlacedLine line,
    Paint brush, {
    Offset shift = Offset.zero,
  }) {
    TextPainter(
      text: TextSpan(
        text: line.span.text,
        style: line.span.style?.copyWith(foreground: brush),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )
      ..layout(maxWidth: line.maxWidth)
      ..paint(canvas, line.at + shift);
  }

  /// [lightFrom] as a direction of length one.
  ///
  /// Separate and pure because it is the part with a rule worth checking:
  /// both walls of the groove are displaced along this one direction, so the
  /// dark side and the lit side stay opposite each other however the lamp is
  /// moved.
  @visibleForTesting
  static Offset normalise(Offset direction) => _normalise(direction);

  static Offset _normalise(Offset direction) {
    final length = direction.distance;
    return length < 1e-6 ? Offset.zero : direction / length;
  }
}

/// A line of lettering, measured and placed.
class _PlacedLine {
  const _PlacedLine({
    required this.span,
    required this.at,
    required this.maxWidth,
    required this.size,
  });

  final TextSpan span;
  final ui.Offset at;
  final double maxWidth;

  /// The type's own size, which the cut is measured from.
  final double size;
}
