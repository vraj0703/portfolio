import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/config/logo_config.dart';
import 'package:portfolio/domain/gallery/gallery_dimensions.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';
import 'package:portfolio/domain/gallery/keyboard_layout.dart';

void main() {
  final pieces = GalleryLayout.build();
  final signs = pieces
      .where((p) => p.kind == SurfaceKind.connectSign)
      .toList();

  group('the invitation in the skills hall', () {
    test('there is exactly one of it', () {
      expect(signs, hasLength(1));
    });

    test('it is painted on the hall\'s entry wall', () {
      final sign = signs.single;

      // Just inside the plaster, not floating in front of it and not buried
      // in it — the wall is a slab centred on its own plane, so anything
      // nudged less than half its thickness is still inside the wall.
      expect(
        sign.position.x,
        greaterThan(GalleryDimensions.kbEntryX),
        reason: 'the sign is behind the wall it is painted on',
      );
      expect(
        sign.position.x - GalleryDimensions.kbEntryX,
        lessThan(0.2),
        reason: 'the sign is floating off the wall',
      );
    });

    test('it faces into the hall', () {
      // A quarter turn puts its face along +x, which is the way in. Half a
      // turn out and the visitor reads it from the alley they have already
      // left, through a wall.
      expect(signs.single.rotationY, closeTo(math.pi / 2, 1e-9));
    });

    test('it hangs on wall, not in the doorway', () {
      final sign = signs.single;
      final segment =
          (GalleryDimensions.kbWidth - GalleryDimensions.wingWidth) / 2;
      final nearEdge = GalleryDimensions.kbZ - GalleryDimensions.wingWidth / 2;
      final farEdge = nearEdge - segment;

      // The entry side is two pieces with the passage between them. A sign
      // centred on the opening would hang in mid-air across the door.
      expect(sign.position.z, lessThan(nearEdge));
      expect(sign.position.z, greaterThan(farEdge));
    });

    test('it hangs on the segment the visitor faces to their right', () {
      // Smaller z than the hall's centre line. The other segment is the one
      // on their left, where this used to be.
      expect(signs.single.position.z, lessThan(GalleryDimensions.kbZ));
    });

    test('it is hung at the height it is read from', () {
      final sign = signs.single;

      // Above the corridor's pictures, because it is met from the board with
      // the camera risen — not from the floor.
      expect(sign.position.y, GalleryDimensions.connectSignY);
      expect(sign.position.y, greaterThan(GalleryDimensions.frameY));
      expect(sign.position.y, lessThan(GalleryDimensions.ceilY));
    });

    test('it is wider than it is tall, like the words on it', () {
      final sign = signs.single;
      expect(sign.extents.x, greaterThan(sign.extents.y * 2));
    });
  });

  group('the instruction behind the board', () {
    final instructions = pieces
        .where((p) => p.kind == SurfaceKind.hallInstruction)
        .toList();

    test('there is exactly one of it', () {
      expect(instructions, hasLength(1));
    });

    test('it is cut into the wall behind the board', () {
      final line = instructions.single;

      // Inside the hall's far wall, not beyond it. The wall is a slab
      // centred on its own plane, so anything short of half its thickness is
      // still buried in it.
      expect(line.position.x, lessThan(GalleryDimensions.kbEndX));
      expect(
        GalleryDimensions.kbEndX - line.position.x,
        lessThan(0.2),
        reason: 'the instruction is floating off the wall',
      );
    });

    test('it faces back down the hall', () {
      // The opposite quarter turn to the invitation on the entry wall: the
      // two walls face each other, so lettering on them cannot share a
      // rotation.
      expect(instructions.single.rotationY, closeTo(-math.pi / 2, 1e-9));
      expect(
        instructions.single.rotationY,
        isNot(closeTo(signs.single.rotationY, 1e-9)),
      );
    });

    test('it is centred on the hall', () {
      expect(instructions.single.position.z, GalleryDimensions.kbZ);
    });

    test('it clears the board rather than sitting behind it', () {
      final line = instructions.single;

      // The board hangs at `hoverHeight` above the floor and tilts toward
      // the visitor. Level with it, the two overlap from the doorway and the
      // instruction is read through the keycaps.
      final board = GalleryDimensions.floorY + KeyboardLayout.hoverHeight;
      expect(line.position.y, greaterThan(board));
      expect(line.position.y, lessThan(GalleryDimensions.ceilY));
    });

    test('it runs wider than it is tall, like the line it carries', () {
      final line = instructions.single;
      expect(line.extents.x, greaterThan(line.extents.y * 4));
    });
  });

  group('the gap the contact menu stands in', () {
    test('is wider than the one "TAP TO ENTER" stands in', () {
      // The menu is seven destinations where the affordance is three words.
      expect(
        LogoConfig.contactGap(1440),
        greaterThan(LogoConfig.lineGap),
      );
    });

    test('never leaves the lines off the edge of a phone', () {
      const narrow = 360.0;
      expect(
        LogoConfig.contactGap(narrow) * 2,
        lessThanOrEqualTo(narrow),
        reason: 'the menu is wider than the screen it is on',
      );
    });

    test('stops growing once there is room enough', () {
      expect(LogoConfig.contactGap(4000), LogoConfig.maxContactGap);
      expect(LogoConfig.contactGap(100), LogoConfig.minContactGap);
    });
  });
}
