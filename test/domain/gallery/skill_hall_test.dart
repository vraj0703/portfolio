import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/gallery_dimensions.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';
import 'package:portfolio/domain/gallery/gallery_camera_path.dart';
import 'package:portfolio/domain/gallery/keyboard_layout.dart';

void main() {
  final walls = GalleryLayout.build()
      .where((p) => p.kind == SurfaceKind.hallWall)
      .toList();

  test('the hall is walled on three sides and open on the fourth', () {
    // Four pieces, not four walls: the entry side is two, with the passage
    // between them. A single wall across it would seal the hall off and the
    // camera would arrive facing plaster.
    expect(walls, hasLength(5));
  });

  test('the passage is exactly the alley that leads to it', () {
    // Not the corridor's width — the alley's. Walking out of the alley
    // should be walking through the door: wider and the hall's own walls are
    // visible from inside the alley, narrower and the visitor threads a gap
    // whose sides they cannot see.
    final entry = walls
        .where((w) => w.position.x == GalleryDimensions.kbEntryX)
        .toList();
    expect(entry, hasLength(2));

    final gap = (entry[0].position.z - entry[1].position.z).abs() -
        entry[0].extents.z;

    expect(gap, closeTo(GalleryDimensions.wingWidth, 1e-6));
  });

  test('the alley is narrower than the corridor feeding it', () {
    // Standing in the hall and looking back, a wide alley puts the far end of
    // the project corridor in view through the doorway and the hall never
    // reads as its own room.
    expect(
      GalleryDimensions.wingWidth,
      lessThan(GalleryDimensions.corridorWidth),
    );
  });

  test('the pan runs down the alley centre, which is the doorway centre', () {
    // If those drift apart the camera arrives at the threshold offset from
    // the opening and has to dogleg through it.
    expect(
      GalleryDimensions.wallLockZ,
      closeTo(
        GalleryDimensions.backWallZ + GalleryDimensions.wingWidth / 2,
        1e-9,
      ),
    );
    expect(GalleryDimensions.kbZ, GalleryDimensions.wallLockZ);
  });

  test('every wall is tall enough to meet the ceiling', () {
    final span = GalleryDimensions.ceilY - GalleryDimensions.floorY;
    for (final wall in walls) {
      expect(wall.extents.y, greaterThanOrEqualTo(span));
    }
  });

  test('the keyboard hangs inside the hall, not through a wall', () {
    final anchor = KeyboardLayout.anchor;
    final half = GalleryDimensions.kbWidth / 2;
    final reach = KeyboardLayout.boardWidth * KeyboardLayout.scale / 2;

    expect(anchor.x - reach, greaterThan(GalleryDimensions.kbX - half));
    expect(anchor.x + reach, lessThan(GalleryDimensions.kbX + half));
    expect(anchor.z, closeTo(GalleryDimensions.kbZ, 1e-6));
  });

  test('the hall sits past the last testimonial, not on top of it', () {
    expect(
      GalleryDimensions.kbEntryX,
      greaterThan(GalleryDimensions.testPanEndX),
      reason: 'the hall would swallow the end of the testimonial wall',
    );
  });

  test('the hall is sized for the board, not for a concourse', () {
    // Twenty-four units left the board adrift in nine metres of empty floor
    // either side, under a ceiling only five high — warehouse proportions.
    //
    // Stated as the board's *share* of the room rather than as a comparison
    // against the floor beside it. The earlier form said the free floor must
    // be narrower than the board, which quietly forbade the board from ever
    // being slim: every time it was trimmed the rule demanded the hall be
    // trimmed with it, and a room cannot keep shrinking to flatter a smaller
    // and smaller object. What matters is that the board still commands the
    // space, and a third of the width does that.
    final board = KeyboardLayout.boardWidth * KeyboardLayout.scale;
    final free = (GalleryDimensions.kbWidth - board) / 2;

    expect(free, greaterThan(2), reason: 'the board is touching the walls');
    expect(
      board / GalleryDimensions.kbWidth,
      greaterThan(0.28),
      reason: 'the board is adrift in the middle of the room',
    );
  });

  test('the visitor comes to rest inside the room, not in the doorway', () {
    // Not a claim about the turn: that eases over whatever distance there is
    // between the door and the stop, so it is smooth however short the walk.
    // This is about where they end up standing — stopping level with the
    // threshold would leave them looking into the hall rather than being in
    // it.
    final walkIn =
        GalleryDimensions.kbDepth / 2 - GalleryCameraPath.hallViewDistance;

    expect(walkIn, greaterThan(1));
  });

  test('the board sits centred between the hall walls', () {
    // The complaint this answers: a square hall put the far wall seven units
    // behind the board and three and a half in front, which read as a long
    // room the board happened to be standing in.
    expect(
      GalleryDimensions.kbX - GalleryDimensions.kbEntryX,
      closeTo(GalleryDimensions.kbEndX - GalleryDimensions.kbX, 1e-9),
    );
  });

  test('the ground reaches under the hall', () {
    // Floor and ceiling are centred on the corridor, so a hall far enough
    // along the wing would stand on nothing.
    final ground = GalleryLayout.groundSize / 2;
    expect(GalleryDimensions.kbX + GalleryDimensions.kbDepth / 2,
        lessThan(ground));
  });
}
