import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/project_data.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/domain/style/strings.dart';
import 'package:portfolio/presentation/gallery/frame_card.dart';

/// The card the corridor's frames carry, baked once to an image.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tantr = GalleryProjects.all.firstWhere((p) => p.id == 'tantr');

  test('the default tone is the warm one; bold is the switch', () {
    expect(FrameCard.tone, ProjectTone.warm);
  });
  const colors = DefaultAppColors();

  // The shape of the card face, at the size the builder bakes it.
  const width = 1024;
  const height = 736;

  Future<ByteData> bake(Project project) async {
    // The project's own colours, which the pixel checks below compare
    // against; the warm default has a test of its own.
    final image = await FrameCard.render(
      project: project,
      width: width,
      height: height,
      tone: ProjectTone.own,
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
    test('every frame with a project, and nothing without one', () {
      for (final p in GalleryProjects.all) {
        expect(FrameCard.paints(p), isTrue, reason: p.id);
      }
      expect(FrameCard.paints(null), isFalse);
    });
  });

  test(
    'a frame that is not ready shows its title and nothing it cannot back',
    () async {
      // Publications is `soon`: its stats are still TODO placeholders, and a
      // card that printed them would put Vishal's to-do list on the wall.
      final soon = GalleryProjects.all.firstWhere((p) => !p.isLive);
      final bytes = await bake(soon);
      final top = (height * FrameCard.margin).round();
      expect(
        inked(bytes, top, top + 100),
        greaterThan(2000),
        reason: 'no title',
      );

      // Below the title and its one line, the card is ground only.
      final lower = inked(bytes, height ~/ 2, height - 10);
      expect(lower, 0, reason: 'a soon card drew more than its title');
    },
  );

  test('the warm tone moves the ground toward the room', () async {
    final own = await FrameCard.render(
      project: tantr,
      width: 64,
      height: 46,
      tone: ProjectTone.own,
    );
    final warm = await FrameCard.render(
      project: tantr,
      width: 64,
      height: 46,
      tone: ProjectTone.warm,
    );
    final a = (await own.toByteData())!;
    final b = (await warm.toByteData())!;
    own.dispose();
    warm.dispose();
    // At the top-left corner the toned ground is nearer the room's walnut
    // than the project's own colour is.
    final walnut = colors.frameCardWarmTop;
    double far(ByteData d) =>
        (d.getUint8(0) - walnut.r * 255).abs() +
        (d.getUint8(1) - walnut.g * 255).abs() +
        (d.getUint8(2) - walnut.b * 255).abs();
    expect(far(b), lessThan(far(a) / 2));
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

  group('the link on the card', () {
    const size = ui.Size(1024, 736);

    test('sits at the foot on the right, inside the margin', () {
      final link = FrameCard.linkRect(size, project: tantr)!;
      final margin = size.width * FrameCard.margin;
      expect(link.right, closeTo(size.width - margin, 0.01));
      expect(
        link.bottom,
        closeTo(size.height - size.height * FrameCard.margin, 0.01),
      );
      expect(
        link.left,
        greaterThan(size.width / 2),
        reason: 'not on the right',
      );
      expect(
        link.height,
        greaterThanOrEqualTo(44),
        reason: 'too small to press',
      );
    });

    test('names where it goes', () {
      expect(
        FrameCard.linkText(tantr, const DefaultAppStrings()),
        contains('tantr.app'),
      );
    });

    test('is absent on work with nowhere to go, or not ready', () {
      for (final project in GalleryProjects.all) {
        final link = FrameCard.linkRect(size, project: project);
        expect(
          link == null,
          !project.isLive || !project.hasLink,
          reason: project.id,
        );
      }
    });

    test('is drawn where it is picked', () async {
      final link = FrameCard.linkRect(size, project: tantr)!;
      final region = FrameCard.linkRegion(size, project: tantr)!;
      expect(region.left * size.width, closeTo(link.left, 1e-6));
      expect(region.bottom * size.height, closeTo(link.bottom, 1e-6));

      // Ink inside the link's rows, right of the stack: the label and edge.
      final bytes = await bake(tantr);
      var inkRight = 0;
      final ink = colors.frameCardInk;
      for (var y = link.top.ceil(); y < link.bottom.floor(); y++) {
        for (var x = link.left.ceil(); x < link.right.floor(); x++) {
          final i = (y * width + x) * 4;
          if ((bytes.getUint8(i) - (ink.r * 255).round()).abs() < 40 &&
              (bytes.getUint8(i + 1) - (ink.g * 255).round()).abs() < 40 &&
              (bytes.getUint8(i + 2) - (ink.b * 255).round()).abs() < 40) {
            inkRight++;
          }
        }
      }
      expect(inkRight, greaterThan(200), reason: 'nothing painted in the link');
    });
  });
}
