import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:portfolio/domain/gallery/skill_data.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/domain/style/text_styles.dart';

/// A keycap's legend, baked once to a small transparent image.
///
/// The FrameCard and WallText way: rasterised at build, bound to an unlit
/// blended quad on the cap's top, never a live widget in the room. The cap
/// is already the skill's accent, so the ink is not: it is near-black on a
/// light cap and near-white on a dark one, chosen by the cap's luminance,
/// with a thin edge of the opposite tone.
///
/// The light/dark split is [inkFor].
///
/// Every cap on a row shares one type size — the size that fits that row's
/// longest label — so a row reads as a set rather than as labels each shrunk
/// to its own length.
abstract final class KeycapLegend {
  /// Edge of the square image each legend is baked into.
  static const int size = 256;

  /// How much of the image's width the longest label on a row may take.
  ///
  /// The image covers 94% of the cap's top (`SkillKeyboard.legendShare`),
  /// so this sets the longest label at about 70% of the cap's width.
  static const double fill = 0.745;

  /// The ink for a legend on [cap], and the edge that keeps it apart:
  /// whichever of near-black and near-white contrasts more with the cap.
  /// By contrast rather than by a luminance cut, because a mid green sits
  /// near any cut and white on it read at under 3:1.
  static (Color ink, Color edge) inkFor(
    Color cap, {
    AppColors colors = const DefaultAppColors(),
  }) {
    final dark = colors.keycapInkDark;
    final light = colors.keycapInkLight;
    return contrast(dark, cap) >= contrast(light, cap)
        ? (dark, light.withValues(alpha: 0.55))
        : (light, dark.withValues(alpha: 0.7));
  }

  /// WCAG contrast ratio between two colours.
  static double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final hi = math.max(la, lb);
    final lo = math.min(la, lb);
    return (hi + 0.05) / (lo + 0.05);
  }

  /// The tallest a legend may stand, as a share of the image, whatever its
  /// row allows across: a row of short labels would otherwise set them as
  /// tall as the cap.
  static const double maxHeight = 0.5;

  /// The type size that fits [row]'s longest label across [fill] of the cap.
  static double fontSizeFor(
    List<Skill> row, {
    AppTypography type = const DefaultAppTypography(),
  }) {
    final base = type.keycapLegend;
    final baseSize = base.fontSize ?? 100;
    var widest = 0.0;
    for (final skill in row) {
      final painter = TextPainter(
        text: TextSpan(text: skill.label, style: base),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      widest = math.max(widest, painter.width);
      painter.dispose();
    }
    if (widest <= 0) return size * maxHeight;
    final across = baseSize * (size * fill) / widest;
    return math.min(across, size * maxHeight);
  }

  /// Bakes [skill]'s legend at [fontSize].
  static Future<ui.Image> render(
    Skill skill, {
    required double fontSize,
    AppColors colors = const DefaultAppColors(),
    AppTypography type = const DefaultAppTypography(),
  }) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final style = type.keycapLegend.copyWith(fontSize: fontSize);

    TextPainter painter(Paint paint) => TextPainter(
      text: TextSpan(
        text: skill.label,
        style: style.copyWith(foreground: paint),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    final (inkColour, edgeColour) = inkFor(skill.color, colors: colors);
    final edge = painter(
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = fontSize * 0.1
        ..strokeJoin = StrokeJoin.round
        ..color = edgeColour,
    );
    final ink = painter(Paint()..color = inkColour);

    // Mirrored left to right: the room's x axis is flipped on the way into
    // the engine (SceneAxes), and a legend baked the right way round arrives
    // reading backwards.
    canvas
      ..translate(size.toDouble(), 0)
      ..scale(-1, 1);
    final at = Offset((size - ink.width) / 2, (size - ink.height) / 2);
    edge.paint(canvas, at);
    ink.paint(canvas, at);
    edge.dispose();
    ink.dispose();

    return recorder.endRecording().toImage(size, size);
  }
}
