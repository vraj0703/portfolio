import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:portfolio/domain/gallery/project_data.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/domain/style/strings.dart';
import 'package:portfolio/domain/style/text_styles.dart';

/// A project's card, rasterised once and bound to the card inside its frame.
///
/// Baked rather than live, for the reason [WallText] gives: a widget surface
/// in the room re-rasterises on its own schedule whether anyone is looking or
/// not, and this content never changes after the room is built.
///
/// Laid out top to bottom in the order a visitor meets it. The title is the
/// only thing that has to carry down the corridor, so it is set an order of
/// magnitude larger than anything else; the line under it, the three stats,
/// the summary and the stack are for the visitor who has stopped and focused
/// the frame, and are sized for that distance.
///
/// Painted on the project's own gradient, top-left to bottom-right, with one
/// ink for every word on every card — the ground changes card to card, so
/// the type is what holds them together as a set.
abstract final class FrameCard {
  /// Whether a frame carries a card: every frame with a project behind it.
  static bool paints(Project? project) => project != null;

  /// How a card's ground is coloured.
  ///
  /// [ProjectTone.warm], the default, tones each project's gradient toward
  /// the room's walnut so the seven sit in the marble: the bold primaries
  /// fought it. [ProjectTone.own] paints each project's own colours and is
  /// one build switch away (`--dart-define=FRAME_TONE=bold`) — mantr's
  /// recommendation is warm, and the call is Vishal's.
  static const ProjectTone tone =
      String.fromEnvironment('FRAME_TONE') == 'bold'
      ? ProjectTone.own
      : ProjectTone.warm;

  /// How far [ProjectTone.warm] moves each stop toward the room's pair.
  static const double warmth = 0.75;

  /// Margin from every edge, as a fraction of the card's width.
  static const double margin = 0.065;

  /// Gaps between the blocks, as a fraction of the card's height.
  static const double gap = 0.035;

  /// Inner padding of a stat or a tag, in pixels at the size baked.
  static const double pillPadX = 18;
  static const double pillPadY = 10;
  static const double pillGap = 14;

  /// How many lines the summary may take before it is cut. Three sentences
  /// at this measure run to three or four lines; a fifth would push the stack
  /// off the card.
  static const int summaryLines = 5;

  /// Bakes [project]'s card at [width] by [height].
  ///
  /// [width] by [height] should match the shape of the card it is going on,
  /// because the texture is stretched to that face; a card baked square and
  /// hung landscape arrives with its type squashed.
  static Future<ui.Image> render({
    required Project project,
    required int width,
    required int height,
    AppColors colors = const DefaultAppColors(),
    AppTypography type = const DefaultAppTypography(),
    AppStrings strings = const DefaultAppStrings(),
    ProjectTone tone = FrameCard.tone,
  }) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    paint(
      canvas,
      Size(width.toDouble(), height.toDouble()),
      project: project,
      colors: colors,
      type: type,
      strings: strings,
      tone: tone,
    );
    return recorder.endRecording().toImage(width, height);
  }

  /// Paints the card into [size] on [canvas]. Separate from [render] so a
  /// test can measure the layout without rasterising it.
  static void paint(
    Canvas canvas,
    Size size, {
    required Project project,
    required AppColors colors,
    required AppTypography type,
    required AppStrings strings,
    ProjectTone tone = ProjectTone.own,
  }) {
    final (own, ownBottom) = project.gradient;
    final top = tone == ProjectTone.warm
        ? Color.lerp(own, colors.frameCardWarmTop, warmth)!
        : own;
    final bottom = tone == ProjectTone.warm
        ? Color.lerp(ownBottom, colors.frameCardWarmBottom, warmth)!
        : ownBottom;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          size.bottomRight(Offset.zero),
          <Color>[top, bottom],
        ),
    );

    final left = size.width * margin;
    final measure = size.width - left * 2;
    final blockGap = size.height * gap;
    var y = size.height * margin;

    // Title.
    y += _text(
      canvas,
      project.title,
      type.frameTitle.copyWith(color: colors.frameCardInk),
      Offset(left, y),
      measure,
      maxLines: 1,
    );

    // Work that is not ready shows its name and says so, and nothing it
    // cannot back yet: no stats, no summary, no stack.
    if (!project.isLive) {
      _text(
        canvas,
        strings.frameComingSoon,
        type.frameDescription.copyWith(color: colors.frameCardInkSoft),
        Offset(left, y),
        measure,
        maxLines: 1,
      );
      return;
    }

    // The one-line description.
    y += _text(
      canvas,
      project.description,
      type.frameDescription.copyWith(color: colors.frameCardInkSoft),
      Offset(left, y),
      measure,
      maxLines: 2,
    );
    y += blockGap;

    // The three stats, in a row.
    y += _pills(
      canvas,
      project.stats,
      type.frameStat.copyWith(color: colors.frameCardInk),
      Offset(left, y),
      measure,
      colors,
    );
    y += blockGap;

    // The stack, pinned to the foot so the summary has whatever is between.
    final tagStyle = type.frameTag.copyWith(color: colors.frameCardInkSoft);
    final tagHeight = _pillHeight(tagStyle);
    final stackTop = size.height - size.height * margin - tagHeight;

    // The way out to the work itself, at the foot on the right, where the
    // eye finishes reading the card. The stack gives way to it.
    final link = linkRect(size, project: project, type: type, strings: strings);
    if (link != null) _link(canvas, link, project, type, strings, colors);
    final stackWidth = link == null ? measure : link.left - pillGap - left;

    if (project.stack.isNotEmpty) {
      _pills(
        canvas,
        project.stack,
        tagStyle,
        Offset(left, stackTop),
        stackWidth,
        colors,
      );
    }

    // The summary, in the room left between the stats and the stack.
    if (project.summary.isNotEmpty) {
      final room = stackTop - blockGap - y;
      final style = type.frameSummary.copyWith(color: colors.frameCardInk);
      final lineHeight = (style.fontSize ?? 30) * (style.height ?? 1.4);
      final lines = math.max(1, math.min(summaryLines, room ~/ lineHeight));
      _text(
        canvas,
        project.summary,
        style,
        Offset(left, y),
        measure,
        maxLines: lines,
      );
    }
  }

  /// Where the link sits on a card baked at [size], in that card's pixels;
  /// null when [project] has nothing to open.
  ///
  /// The one place the link's geometry is decided. [paint] draws it here and
  /// the gallery picks it here (through [linkRegion]), so what is pressed is
  /// always exactly what is drawn.
  static Rect? linkRect(
    Size size, {
    required Project project,
    AppTypography type = const DefaultAppTypography(),
    AppStrings strings = const DefaultAppStrings(),
  }) {
    if (!project.isLive || !project.hasLink) return null;

    final painter = TextPainter(
      text: TextSpan(text: linkText(project, strings), style: type.frameLink),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final width = painter.width + linkPadX * 2;
    final height = painter.height + linkPadY * 2;
    painter.dispose();

    final right = size.width - size.width * margin;
    final bottom = size.height - size.height * margin;
    return Rect.fromLTRB(right - width, bottom - height, right, bottom);
  }

  /// [linkRect] as a share of the card, `0..1` on both axes, which is how
  /// the gallery asks after a press on the focused frame.
  static Rect? linkRegion(
    Size size, {
    required Project project,
    AppTypography type = const DefaultAppTypography(),
    AppStrings strings = const DefaultAppStrings(),
  }) {
    final rect = linkRect(size, project: project, type: type, strings: strings);
    if (rect == null) return null;
    return Rect.fromLTRB(
      rect.left / size.width,
      rect.top / size.height,
      rect.right / size.width,
      rect.bottom / size.height,
    );
  }

  /// What the link says: where it goes, by its host.
  static String linkText(Project project, AppStrings strings) =>
      strings.frameLink(Uri.parse(project.url).host.replaceFirst('www.', ''));

  /// Inner padding of the link, in pixels at the size baked. Roomier than a
  /// tag: it is the one thing on the card that is pressed.
  static const double linkPadX = 26;
  static const double linkPadY = 14;

  static void _link(
    Canvas canvas,
    Rect at,
    Project project,
    AppTypography type,
    AppStrings strings,
    AppColors colors,
  ) {
    final box = RRect.fromRectAndRadius(at, Radius.circular(at.height / 2));
    canvas
      ..drawRRect(box, Paint()..color = colors.frameCardLinkFill)
      ..drawRRect(
        box,
        Paint()
          ..color = colors.frameCardInk
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    final painter = TextPainter(
      text: TextSpan(
        text: linkText(project, strings),
        style: type.frameLink.copyWith(color: colors.frameCardInk),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    painter.paint(
      canvas,
      Offset(at.left + linkPadX, at.top + (at.height - painter.height) / 2),
    );
    painter.dispose();
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

  static double _pillHeight(TextStyle style) =>
      (style.fontSize ?? 20) * (style.height ?? 1.2) + pillPadY * 2;

  /// Draws [labels] as a row of rounded tags from [at], stopping at the last
  /// one that fits in [width], and returns the row's height.
  static double _pills(
    Canvas canvas,
    List<String> labels,
    TextStyle style,
    Offset at,
    double width,
    AppColors colors,
  ) {
    final height = _pillHeight(style);
    final radius = Radius.circular(height / 2);
    final fill = Paint()..color = colors.frameCardTagFill;
    final edge = Paint()
      ..color = colors.frameCardTagEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    var x = at.dx;
    for (final label in labels) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      final pill = painter.width + pillPadX * 2;
      if (x + pill > at.dx + width) {
        painter.dispose();
        break;
      }
      final box = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, at.dy, pill, height),
        radius,
      );
      canvas
        ..drawRRect(box, fill)
        ..drawRRect(box, edge);
      painter.paint(
        canvas,
        Offset(x + pillPadX, at.dy + (height - painter.height) / 2),
      );
      painter.dispose();
      x += pill + pillGap;
    }
    return height;
  }
}

/// How a card's ground is coloured; see [FrameCard.tone].
enum ProjectTone { own, warm }
