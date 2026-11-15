import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:portfolio/domain/gallery/gallery_dimensions.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';
import 'package:portfolio/domain/gallery/piece_art.dart';
import 'package:portfolio/domain/gallery/project_data.dart';
import 'package:portfolio/domain/gallery/wall_label.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/domain/style/text_styles.dart';

/// Where the two faces sit in one piece's baked image.
///
/// One image per piece holds both its paper (the mat and the drawing) and
/// its wall label, side by side, and each face samples its own part of it.
/// Seven pieces stay seven textures: the loading work of PORTFOLIO-8 is
/// counted in uploads and in pixels, and a second texture per piece for the
/// label would have doubled the one and added to the other.
class PieceAtlas {
  const PieceAtlas({
    required this.size,
    required this.piece,
    required this.label,
  });

  /// The whole image, in pixels.
  final Size size;

  /// The piece's paper, inside its moulding.
  final Rect piece;

  /// The wall label.
  final Rect label;

  /// [region] as a share of the image, `0..1`: the offset and scale a face
  /// samples it with.
  Rect share(Rect region) => Rect.fromLTWH(
    region.left / size.width,
    region.top / size.height,
    region.width / size.width,
    region.height / size.height,
  );
}

/// A piece of the corridor, baked once: the paper, the drawing in ink with
/// its one accent, and the wall label that hangs beside it.
///
/// Baked rather than live, for the reason `WallText` gives: a widget surface
/// in the room re-rasterises on its own schedule whether anyone is looking or
/// not, and this content never changes after the room is built.
///
/// No words on the piece. The drawing is made from the project's own facts
/// (see [PieceDrawing]); the name, the line, the number, the tags and the
/// years are the label's, and everything else is the sheet's.
abstract final class PieceCard {
  /// The paper showing round the drawing, on every side, as a share of the
  /// paper's width (the mock's 9%).
  static const double mat = 0.09;

  /// Pixels to a unit of the room, for the paper and for the label.
  ///
  /// The label is denser: it carries type, read close. The paper carries
  /// lines, which hold at less. Together they come to fewer pixels than the
  /// 1024 x 736 slide each frame used to carry, so the upload and the mip
  /// chain cost no more than before.
  static const double paperDensity = 240;
  static const double labelDensity = 300;

  /// Clear paper between the two faces, so a mip level that averages across
  /// the seam averages paper into paper.
  static const double seam = 16;

  /// How strongly a piece still in preparation is drawn: dimmer, as its
  /// light is.
  static const double soonStrength = 0.42;

  /// The label's inner margin, as a share of its width.
  static const double labelMargin = 0.065;

  /// Inner padding of a tag, and the room between two, in label pixels.
  static const double tagPadX = 10;
  static const double tagPadY = 5;
  static const double tagGap = 8;

  /// The image's layout at [scale] (1 at the densities above).
  static PieceAtlas atlas({double scale = 1}) {
    final paperW = (GalleryLayout.pieceWidth - GalleryLayout.pieceBorder * 2) *
        paperDensity *
        scale;
    final paperH =
        (GalleryDimensions.frameMaxHeight - GalleryLayout.pieceBorder * 2) *
        paperDensity *
        scale;
    final labelW = GalleryLayout.labelWidth * labelDensity * scale;
    final labelH = GalleryLayout.labelHeight * labelDensity * scale;
    final piece = Rect.fromLTWH(0, 0, paperW.roundToDouble(), paperH.roundToDouble());
    final label = Rect.fromLTWH(
      piece.right + seam,
      0,
      labelW.roundToDouble(),
      labelH.roundToDouble(),
    );
    return PieceAtlas(
      size: Size(label.right, math.max(piece.bottom, label.bottom)),
      piece: piece,
      label: label,
    );
  }

  /// Where the drawing's 400 x 500 field lands on the paper: inside the mat,
  /// as large as it fits, centred.
  static Rect fieldIn(Rect paper) {
    final inner = paper.deflate(paper.width * mat);
    final k = math.min(
      inner.width / PieceDrawing.field.width,
      inner.height / PieceDrawing.field.height,
    );
    return Rect.fromCenter(
      center: inner.center,
      width: PieceDrawing.field.width * k,
      height: PieceDrawing.field.height * k,
    );
  }

  /// Bakes [project]'s piece and label into one image.
  static Future<ui.Image> render({
    required Project project,
    double scale = 1,
    AppColors colors = const DefaultAppColors(),
    AppTypography type = const DefaultAppTypography(),
  }) {
    final layout = atlas(scale: scale);
    final recorder = ui.PictureRecorder();
    paint(
      Canvas(recorder),
      layout,
      project: project,
      colors: colors,
      type: type,
      scale: scale,
    );
    return recorder.endRecording().toImage(
      layout.size.width.round(),
      layout.size.height.round(),
    );
  }

  /// Paints both faces into [layout] on [canvas]. Separate from [render] so
  /// a test can measure without rasterising.
  static void paint(
    Canvas canvas,
    PieceAtlas layout, {
    required Project project,
    required AppColors colors,
    required AppTypography type,
    double scale = 1,
  }) {
    // Paper everywhere first, the seam included.
    canvas.drawRect(
      Offset.zero & layout.size,
      Paint()..color = colors.piecePaper,
    );
    paintDrawing(
      canvas,
      fieldIn(layout.piece),
      art: project.art,
      accent: project.accent,
      colors: colors,
      strength: project.isLive ? 1 : soonStrength,
    );
    paintLabel(
      canvas,
      layout.label,
      project: project,
      colors: colors,
      type: type,
      scale: scale,
    );
  }

  /// Draws [art] into [field], in ink with [accent] for its one mark of
  /// colour.
  static void paintDrawing(
    Canvas canvas,
    Rect field, {
    required PieceArt art,
    required Color accent,
    required AppColors colors,
    double strength = 1,
  }) {
    final k = field.width / PieceDrawing.field.width;
    canvas.save();
    if (strength < 1) {
      canvas.saveLayer(
        field.inflate(field.width * mat),
        Paint()..color = Color.fromRGBO(0, 0, 0, strength),
      );
    }
    canvas
      ..translate(field.left, field.top)
      ..scale(k);

    final ink = colors.pieceInk;
    for (final mark in PieceDrawing.marks(art)) {
      final path = mark.shape.path();
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = mark.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final fill = Paint()..style = PaintingStyle.fill;
      switch (mark.ink) {
        case ArtInk.line || ArtInk.line2 || ArtInk.line3:
          canvas.drawPath(path, stroke..color = ink);
        case ArtInk.faint:
          canvas.drawPath(
            path,
            stroke
              ..color = ink.withValues(alpha: 0.28)
              ..strokeCap = StrokeCap.butt,
          );
        case ArtInk.fill:
          canvas.drawPath(path, fill..color = ink);
        case ArtInk.hollow:
          canvas
            ..drawPath(path, fill..color = colors.piecePaper)
            ..drawPath(path, stroke..color = ink);
        case ArtInk.accent:
          canvas.drawPath(path, fill..color = accent);
        case ArtInk.accentLine:
          canvas.drawPath(path, stroke..color = accent);
      }
    }
    if (strength < 1) canvas.restore();
    canvas.restore();
  }

  /// Sets [project]'s wall label in [at]: name, line, number, tags, years,
  /// each only when the project has it.
  static void paintLabel(
    Canvas canvas,
    Rect at, {
    required Project project,
    required AppColors colors,
    required AppTypography type,
    double scale = 1,
  }) {
    canvas
      ..save()
      ..clipRect(at)
      ..drawRect(at, Paint()..color = colors.labelPaper);

    final pad = at.width * labelMargin;
    final measure = at.width - pad * 2;
    final gap = 12 * scale;
    var y = at.top + pad;
    final x = at.left + pad;

    TextStyle sized(TextStyle s, Color c) =>
        s.copyWith(color: c, fontSize: (s.fontSize ?? 14) * scale);

    final label = WallLabel.of(project);
    for (final row in label.rows) {
      switch (row) {
        case LabelRow.name:
          y += _text(canvas, project.title,
              sized(type.labelName, colors.labelInk), Offset(x, y), measure,
              maxLines: 2);
        case LabelRow.line:
          y += gap +
              _text(canvas, project.line,
                  sized(type.labelLine, colors.labelInkSoft), Offset(x, y + gap),
                  measure, maxLines: 3);
        case LabelRow.figure:
          y += gap +
              _text(canvas, project.figure,
                  sized(type.labelFigure, colors.labelInk), Offset(x, y + gap),
                  measure, maxLines: 1);
        case LabelRow.tags:
          y += gap +
              _tags(canvas, project.tags.take(WallLabel.maxTags).toList(),
                  sized(type.labelTag, colors.labelInk), Offset(x, y + gap),
                  measure, colors, scale);
        case LabelRow.years:
          y += gap +
              _text(canvas, project.years,
                  sized(type.labelYears, colors.labelInkSoft),
                  Offset(x, y + gap), measure, maxLines: 1);
      }
    }
    canvas.restore();
  }

  /// Lays [text] out within [width] at [at] and returns the height it took.
  static double _text(
    Canvas canvas,
    String text,
    TextStyle style,
    Offset at,
    double width, {
    required int maxLines,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: '…',
    )..layout(maxWidth: width);
    painter.paint(canvas, at);
    final height = painter.height;
    painter.dispose();
    return height;
  }

  /// Draws [labels] as outlined tags from [at], wrapping onto a second row
  /// when they do not fit one, and returns the height they took.
  static double _tags(
    Canvas canvas,
    List<String> labels,
    TextStyle style,
    Offset at,
    double width,
    AppColors colors,
    double scale,
  ) {
    final padX = tagPadX * scale, padY = tagPadY * scale, gap = tagGap * scale;
    final height = (style.fontSize ?? 16) * (style.height ?? 1.2) + padY * 2;
    final edge = Paint()
      ..color = colors.labelTagEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;
    var x = at.dx, y = at.dy;
    for (final text in labels) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      final w = painter.width + padX * 2;
      if (x > at.dx && x + w > at.dx + width) {
        x = at.dx;
        y += height + gap;
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w, height),
          Radius.circular(height / 2),
        ),
        edge,
      );
      painter.paint(canvas, Offset(x + padX, y + (height - painter.height) / 2));
      painter.dispose();
      x += w + gap;
    }
    return y + height - at.dy;
  }
}
