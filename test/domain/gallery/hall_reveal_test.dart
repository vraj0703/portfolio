import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/gallery_camera_path.dart';
import 'package:portfolio/domain/gallery/gallery_dimensions.dart';
import 'package:portfolio/domain/gallery/keyboard_layout.dart';

void main() {
  double atHall(double t) =>
      GalleryCameraPath.panEnd + GalleryCameraPath.hallFraction * t;

  /// How far the camera has turned from the far wall toward the board.
  double facing(double progress) {
    final pose = GalleryCameraPath.poseAt(progress);
    final board = KeyboardLayout.anchor;
    final toWall =
        (pose.target.z - GalleryDimensions.backWallZ).abs();
    final toBoard = (pose.target.x - board.x).abs();
    return toWall / (toWall + toBoard + 1e-9);
  }

  test('the visitor is facing the hall before the board rises', () {
    // The bug this exists for: the board rose while the camera was still
    // tracking the far wall, ninety degrees away from the hall. The entrance
    // happened where nobody could see it, and the board was simply already
    // standing there by the time anyone looked.
    expect(
      GalleryCameraPath.revealAt(atHall(GalleryCameraPath.revealStart)),
      closeTo(0, 1e-9),
      reason: 'the board starts rising before the turn has finished',
    );

    expect(
      facing(atHall(GalleryCameraPath.revealStart)),
      greaterThan(0.9),
      reason: 'the camera is still looking at the far wall',
    );
  });

  test('the board has finished rising before the visitor sets off', () {
    expect(
      GalleryCameraPath.revealAt(atHall(GalleryCameraPath.revealEnd)),
      closeTo(1, 1e-9),
    );
  });

  test('the camera holds still while the board rises', () {
    // Moving and revealing at once puts two events on top of each other and
    // neither reads.
    final start = GalleryCameraPath.poseAt(
      atHall(GalleryCameraPath.revealStart),
    );
    final end = GalleryCameraPath.poseAt(atHall(GalleryCameraPath.revealEnd));

    expect(start.position.x, closeTo(end.position.x, 1e-6));
    expect(start.position.x, closeTo(GalleryDimensions.kbEntryX, 1e-6));
  });

  test('the reveal runs only inside the hall stretch', () {
    expect(GalleryCameraPath.revealAt(0), 0);
    expect(GalleryCameraPath.revealAt(GalleryCameraPath.panEnd), 0);
    expect(GalleryCameraPath.revealAt(1), 1);
  });

  test('the walk in starts where the reveal stops', () {
    final held = GalleryCameraPath.poseAt(atHall(GalleryCameraPath.revealEnd));
    final moved = GalleryCameraPath.poseAt(
      atHall(GalleryCameraPath.revealEnd + 0.05),
    );

    expect(moved.position.x, greaterThan(held.position.x));
  });
}
