import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/testimonial_data.dart';
import 'package:portfolio/domain/style/colors.dart';
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
}
