import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/project_data.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/presentation/gallery/frame_card.dart';

/// The card the corridor's frames carry, baked once to an image.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tantr = GalleryProjects.all.firstWhere((p) => p.id == 'tantr');
  const colors = DefaultAppColors();

  // The shape of the card face, at the size the builder bakes it.
  const width = 1024;
  const height = 736;

  Future<ByteData> bake(Project project) async {
    final image = await FrameCard.render(
      project: project,
      width: width,
      height: height,
    );
    expect(image.width, width);
    expect(image.height, height);
    final bytes = (await image.toByteData())!;
    image.dispose();
    return bytes;
  }

  /// How many pixels in rows [top]..[bottom] are set in the card's ink.
  int inked(ByteData bytes, int top, int bottom) {
    final ink = colors.frameCardInk;
    final r = (ink.r * 255).round();
    final g = (ink.g * 255).round();
    final b = (ink.b * 255).round();
    var count = 0;
    for (var y = top; y < bottom; y++) {
      for (var x = 0; x < width; x++) {
        final i = (y * width + x) * 4;
        if ((bytes.getUint8(i) - r).abs() < 40 &&
            (bytes.getUint8(i + 1) - g).abs() < 40 &&
            (bytes.getUint8(i + 2) - b).abs() < 40) {
          count++;
        }
      }
    }
    return count;
  }

  group('which frames carry a card', () {
    test('slice one paints the tantr frame and no other', () {
      expect(FrameCard.paints(tantr), isTrue);
      for (final p in GalleryProjects.all.where((p) => p.id != 'tantr')) {
        expect(FrameCard.paints(p), isFalse, reason: p.id);
      }
      expect(FrameCard.paints(null), isFalse);
    });
  });

  group('the tantr card', () {
    test('is painted on the project gradient, not on white', () async {
      final bytes = await bake(tantr);
      final (top, _) = tantr.gradient;

      // The top-left corner is inside the margin, so it is ground only.
      expect(bytes.getUint8(0), closeTo((top.r * 255).round(), 6));
      expect(bytes.getUint8(1), closeTo((top.g * 255).round(), 6));
      expect(bytes.getUint8(2), closeTo((top.b * 255).round(), 6));
    });

    test('carries its title in the top band, large', () async {
      final bytes = await bake(tantr);
      final top = (height * FrameCard.margin).round();

      // The first hundred rows inside the margin are the title's, and hold a
      // title's worth of ink.
      final title = inked(bytes, top, top + 100);
      expect(title, greaterThan(2000), reason: 'no title in the top band');
    });

    test('carries the stack as tags at the foot', () async {
      final bytes = await bake(tantr);
      final foot = height - (height * FrameCard.margin).round();
      // The tags' fill and edge are lighter than the gradient under them.
      var lifted = 0;
      final (_, bottom) = tantr.gradient;
      final base = (bottom.g * 255).round();
      for (var y = foot - 40; y < foot; y++) {
        for (var x = 0; x < width; x++) {
          if (bytes.getUint8((y * width + x) * 4 + 1) > base + 40) lifted++;
        }
      }
      expect(lifted, greaterThan(300), reason: 'no tags at the foot');
    });
  });

  test('a card with no summary and no stack still bakes', () async {
    // The frames still waiting on Vishal's facts have neither; the painter
    // must not assume them.
    const bare = Project(
      id: 'bare',
      title: 'Bare',
      description: 'Nothing else',
      url: '#',
      gradient: (ui.Color(0xFF4338CA), ui.Color(0xFF1E1B4B)),
      stats: <String>['One', 'Two', 'Three'],
      visual: ProjectVisual.graph,
    );
    await bake(bare);
  });
}
