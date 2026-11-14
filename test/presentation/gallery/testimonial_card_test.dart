import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/testimonial_data.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/domain/style/strings.dart';
import 'package:portfolio/presentation/gallery/testimonial_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const colors = DefaultAppColors();
  const width = 512;
  const height = 368;

  Future<ByteData> bake(
    TestimonialSlot slot, {
    PendingRecommendation? p,
  }) async {
    final image = await TestimonialCard.render(
      slot: slot,
      pending: p,
      width: width,
      height: height,
    );
    expect(image.width, width);
    expect(image.height, height);
    final bytes = (await image.toByteData())!;
    image.dispose();
    return bytes;
  }

  /// Pixels in rows [top]..[bottom] near the card's ink.
  int inked(ByteData bytes, int top, int bottom) {
    final ink = colors.frameCardInk;
    var n = 0;
    for (var y = top; y < bottom; y++) {
      for (var x = 0; x < width; x++) {
        final i = (y * width + x) * 4;
        if ((bytes.getUint8(i) - ink.r * 255).abs() < 40 &&
            (bytes.getUint8(i + 1) - ink.g * 255).abs() < 40 &&
            (bytes.getUint8(i + 2) - ink.b * 255).abs() < 40) {
          n++;
        }
      }
    }
    return n;
  }

  test('the first frame carries the title, at the top', () async {
    final bytes = await bake(TestimonialSlot.invitation);
    final top = (height * TestimonialCard.margin).round();
    expect(inked(bytes, top, top + 50), greaterThan(300));
  });

  test('a reserved frame is quiet: no title, no quote', () async {
    // The empty frames are waiting, not pretending: nothing in the card's ink
    // at the top where a title or a quote would start.
    final bytes = await bake(TestimonialSlot.reserved);
    final top = (height * TestimonialCard.margin).round();
    expect(inked(bytes, top, top + 50), 0);
  });

  test("a visitor's own words fill frame 2", () async {
    const mine = PendingRecommendation(
      name: 'Asha',
      role: 'Lead',
      relationship: 'Managed Vishal',
      words: 'Calm under pressure, and kind with it.',
    );
    final bytes = await bake(TestimonialSlot.pending, p: mine);
    final top = (height * TestimonialCard.margin).round();
    expect(inked(bytes, top, top + 40), greaterThan(100));
  });

  group('the invitation carries the button', () {
    const size = ui.Size(1024, 736);

    test('at the foot on the right, big enough to press', () {
      final button = TestimonialCard.buttonRect(size);
      final margin = size.width * TestimonialCard.margin;
      expect(button.right, closeTo(size.width - margin, 0.01));
      expect(
        button.bottom,
        closeTo(size.height - size.height * TestimonialCard.margin, 0.01),
      );
      expect(button.left, greaterThan(size.width / 2));
      expect(button.height, greaterThanOrEqualTo(44));
    });

    test('says add yours', () {
      expect(
        TestimonialCard.buttonText(const DefaultAppStrings()),
        startsWith('add yours'),
      );
    });

    test('the region is the rect as a share of the card', () {
      final rect = TestimonialCard.buttonRect(size);
      final region = TestimonialCard.buttonRegion(size);
      expect(region.left * size.width, closeTo(rect.left, 1e-6));
      expect(region.bottom * size.height, closeTo(rect.bottom, 1e-6));
    });

    test('is painted on the invitation and nowhere else', () async {
      final rect = TestimonialCard.buttonRect(size);
      Future<int> inked(TestimonialSlot slot) async {
        final image = await TestimonialCard.render(
          slot: slot,
          width: size.width.toInt(),
          height: size.height.toInt(),
        );
        final bytes = (await image.toByteData())!;
        final w = image.width;
        image.dispose();
        final ink = const DefaultAppColors().frameCardInk;
        var count = 0;
        for (var y = rect.top.ceil(); y < rect.bottom.floor(); y++) {
          for (var x = rect.left.ceil(); x < rect.right.floor(); x++) {
            final i = (y * w + x) * 4;
            if ((bytes.getUint8(i) - (ink.r * 255).round()).abs() < 40 &&
                (bytes.getUint8(i + 1) - (ink.g * 255).round()).abs() < 40 &&
                (bytes.getUint8(i + 2) - (ink.b * 255).round()).abs() < 40) {
              count++;
            }
          }
        }
        return count;
      }

      expect(await inked(TestimonialSlot.invitation), greaterThan(200));
      expect(await inked(TestimonialSlot.reserved), 0);
    });
  });
}
