import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_scene/scene.dart';
import 'package:portfolio/domain/gallery/testimonial_data.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/domain/style/strings.dart';
import 'package:portfolio/domain/style/text_styles.dart';
import 'package:vector_math/vector_math.dart';

/// A testimonial frame's card, baked once like a project's [FrameCard].
///
/// On the room's own walnut rather than a project gradient: these frames hold
/// other people's words, not Vishal's work, and the wall reads as one thing.
abstract final class TestimonialCard {
  static const double margin = 0.08;

  /// The most lines a visitor's own words may take on the card.
  static const int wordsLines = 7;

  static Future<ui.Image> render({
    required TestimonialSlot slot,
    required int width,
    required int height,
    PendingRecommendation? pending,
    AppColors colors = const DefaultAppColors(),
    AppTypography type = const DefaultAppTypography(),
    AppStrings strings = const DefaultAppStrings(),
  }) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(width.toDouble(), height.toDouble());

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          size.bottomRight(Offset.zero),
          <Color>[colors.frameCardWarmTop, colors.frameCardWarmBottom],
        ),
    );

    final left = size.width * margin;
    final measure = size.width - left * 2;
    final ink = colors.frameCardInk;
    final soft = colors.frameCardInkSoft;

    switch (slot) {
      case TestimonialSlot.invitation:
        var y = size.height * margin;
        y += _text(
          canvas,
          strings.testimonialsTitle,
          type.frameTitle.copyWith(color: ink),
          Offset(left, y),
          measure,
          maxLines: 1,
        );
        y += size.height * 0.03;
        _text(
          canvas,
          strings.testimonialsInvite,
          type.frameSummary.copyWith(color: soft),
          Offset(left, y),
          measure,
          maxLines: 3,
        );
        _button(
          canvas,
          buttonRect(size, type: type, strings: strings),
          type,
          strings,
          colors,
        );

      case TestimonialSlot.reserved:
        // Quiet, and centred: an empty frame waiting, not a placeholder
        // pretending to be a quote.
        final painter = TextPainter(
          text: TextSpan(
            text: strings.testimonialsReserved,
            style: type.frameDescription.copyWith(
              color: soft.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          maxLines: 2,
        )..layout(maxWidth: measure);
        painter.paint(
          canvas,
          Offset(
            (size.width - painter.width) / 2,
            (size.height - painter.height) / 2,
          ),
        );
        painter.dispose();

      case TestimonialSlot.pending:
        final words = pending;
        if (words == null) break;
        var y = size.height * margin;
        y += _text(
          canvas,
          '“${words.words.trim()}”',
          type.frameSummary.copyWith(color: ink),
          Offset(left, y),
          measure,
          maxLines: wordsLines,
        );
        y += size.height * 0.04;
        y += _text(
          canvas,
          '— ${words.signature}',
          type.frameDescription.copyWith(color: soft),
          Offset(left, y),
          measure,
          maxLines: 2,
        );
        if (words.relationship.trim().isNotEmpty) {
          _text(
            canvas,
            words.relationship.trim(),
            type.frameTag.copyWith(color: soft),
            Offset(left, y + 6),
            measure,
            maxLines: 1,
          );
        }
        _pendingMark(canvas, size, strings.testimonialPending, type, colors);
    }

    return recorder.endRecording().toImage(width, height);
  }

  /// Where the invitation's button sits on a card baked at [size], in that
  /// card's pixels: at the foot on the right, like a project card's link.
  ///
  /// The one place its geometry is decided. The invitation is drawn with it
  /// here and the gallery picks it here (through [buttonRegion]), so what is
  /// pressed is exactly what is drawn.
  static Rect buttonRect(
    Size size, {
    AppTypography type = const DefaultAppTypography(),
    AppStrings strings = const DefaultAppStrings(),
  }) {
    final painter = TextPainter(
      text: TextSpan(text: buttonText(strings), style: type.frameLink),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final width = painter.width + buttonPadX * 2;
    final height = painter.height + buttonPadY * 2;
    painter.dispose();

    final right = size.width - size.width * margin;
    final bottom = size.height - size.height * margin;
    return Rect.fromLTRB(right - width, bottom - height, right, bottom);
  }

  /// [buttonRect] as a share of the card, `0..1` on both axes.
  static Rect buttonRegion(
    Size size, {
    AppTypography type = const DefaultAppTypography(),
    AppStrings strings = const DefaultAppStrings(),
  }) {
    final rect = buttonRect(size, type: type, strings: strings);
    return Rect.fromLTRB(
      rect.left / size.width,
      rect.top / size.height,
      rect.right / size.width,
      rect.bottom / size.height,
    );
  }

  /// What the button says.
  static String buttonText(AppStrings strings) =>
      strings.cardButton(strings.recommendAddYours);

  /// Inner padding of the button, in pixels at the size baked.
  static const double buttonPadX = 26;
  static const double buttonPadY = 14;

  static void _button(
    Canvas canvas,
    Rect at,
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
        text: buttonText(strings),
        style: type.frameLink.copyWith(color: colors.frameCardInk),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    painter.paint(
      canvas,
      Offset(at.left + buttonPadX, at.top + (at.height - painter.height) / 2),
    );
    painter.dispose();
  }

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

  /// "PENDING", in a pill in the corner: the words are the visitor's, not yet
  /// a recommendation Vishal has received.
  static void _pendingMark(
    Canvas canvas,
    Size size,
    String word,
    AppTypography type,
    AppColors colors,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: word.toUpperCase(),
        style: type.frameStat.copyWith(color: colors.frameCardInk),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    const padX = 18.0;
    const padY = 10.0;
    final w = painter.width + padX * 2;
    final h = painter.height + padY * 2;
    final at = Offset(
      size.width - size.width * margin - w,
      size.height - size.height * margin - h,
    );
    final box = RRect.fromRectAndRadius(
      at & Size(w, h),
      Radius.circular(h / 2),
    );
    canvas
      ..drawRRect(box, Paint()..color = colors.frameCardTagFill)
      ..drawRRect(
        box,
        Paint()
          ..color = colors.frameCardTagEdge
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    painter.paint(canvas, at + const Offset(padX, padY));
    painter.dispose();
  }
}

/// The testimonial wall's cards, as built, and the one that can change.
///
/// Frame 2 shows a visitor's own words the moment they write them, so its
/// card is kept: [show] re-bakes it, binds the new image, and plays the
/// entrance — the card growing back onto the wall — over [entrance].
class TestimonialCards {
  /// How long the pending card takes to arrive.
  static const double entrance = 0.7;

  Node? _node;
  UnlitMaterial? _material;
  Matrix4? _base;
  int _width = 0;
  int _height = 0;
  double _reveal = 1;

  int _next = 0;

  /// Images and textures this made after the build, released with the room.
  final List<ui.Image> images = <ui.Image>[];
  final List<Texture2D> textures = <Texture2D>[];

  /// The slot of the next testimonial frame the builder hangs.
  int nextSlot() => _next++;

  /// Keeps the pending frame's card so [show] can change it later.
  void attach(
    Node node,
    UnlitMaterial material,
    Matrix4 base, {
    required int width,
    required int height,
  }) {
    _node = node;
    _material = material;
    _base = Matrix4.copy(base);
    _width = width;
    _height = height;
  }

  /// Puts [pending] on frame 2 and plays its entrance.
  Future<void> show(PendingRecommendation pending) async {
    final material = _material;
    if (material == null) return;

    final image = await TestimonialCard.render(
      slot: TestimonialSlot.pending,
      pending: pending,
      width: _width,
      height: _height,
    );
    images.add(image);
    final texture = await Texture2D.fromImage(image);
    textures.add(texture);
    material.baseColorTexture = texture;
    _reveal = 0;
    _place();
  }

  /// Advances the entrance by [dt] seconds.
  void tick(double dt) {
    if (_reveal >= 1) return;
    _reveal = math.min(1, _reveal + dt / entrance);
    _place();
  }

  void _place() {
    final node = _node;
    final base = _base;
    if (node == null || base == null) return;

    // Ease out with a little overshoot, so the card settles onto the wall
    // rather than stopping dead.
    final t = _reveal;
    const c = 1.4;
    final eased = 1 + (c + 1) * math.pow(t - 1, 3) + c * math.pow(t - 1, 2);
    final s = 0.6 + 0.4 * eased;
    node.localTransform = Matrix4.copy(base)..scaleByDouble(s, s, 1, 1);
  }
}
