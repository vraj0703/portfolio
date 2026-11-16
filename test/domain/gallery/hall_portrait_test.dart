import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/gallery_camera_path.dart';
import 'package:portfolio/domain/gallery/gallery_dimensions.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';
import 'package:portfolio/domain/gallery/keyboard_layout.dart';
import 'package:portfolio/domain/gallery/keyboard_orbit.dart';
import 'package:vector_math/vector_math.dart';

/// The skills hall on a portrait phone (PORTFOLIO-13): the whole instruction
/// readable from where the hall rests, the whole board reachable by turning
/// round it, and the camera inside the hall throughout.
void main() {
  // A 390 and a 360 wide phone, and a 9:16 one.
  const phones = <String, double>{
    '390x844': 390 / 844,
    '360x800': 360 / 800,
    '9:16': 9 / 16,
  };
  final instruction = GalleryLayout.build()
      .singleWhere((p) => p.kind == SurfaceKind.hallInstruction);
  CameraPose restFor(double aspect) => GalleryCameraPath.orbitPose(
    0,
    GalleryCameraPath.hallRestElevation,
    aspect: aspect,
  );

  /// Half the horizontal field of view, as a tangent, at [aspect].
  double halfWidth(double aspect) =>
      math.tan(GalleryDimensions.fovRadians / 2) * aspect;

  bool insideHall(Vector3 p) =>
      p.x > GalleryDimensions.kbEntryX &&
      p.x < GalleryDimensions.kbEndX &&
      (p.z - GalleryDimensions.kbZ).abs() < GalleryDimensions.kbWidth / 2 &&
      p.y < GalleryDimensions.ceilY;

  test('the whole instruction is in the shot from the resting pose', () {
    // The wall is square to the view at rest: its width against what the
    // screen sees at that distance.
    for (final MapEntry(key: name, value: aspect) in phones.entries) {
      final rest = restFor(aspect);
      final distance = instruction.position.x - rest.position.x;
      final seen = 2 * halfWidth(aspect) * distance;
      expect(
        instruction.extents.x,
        lessThan(seen),
        reason: '$name sees ${seen.toStringAsFixed(2)} m of the far wall',
      );
    }
  });

  test('the instruction is in the shot top to bottom, too', () {
    final rest = restFor(phones['390x844']!);
    final distance = instruction.position.x - rest.position.x;
    final half = math.tan(GalleryDimensions.fovRadians / 2) * distance;
    // The view is pitched down toward the board; the sign is above it. Its
    // top must be under the top of the view at the wall.
    final pitch = math.atan2(
      rest.target.y - rest.position.y,
      rest.target.x - rest.position.x,
    );
    final centreAtWall = rest.position.y + math.tan(pitch) * distance;
    final top = instruction.position.y + instruction.extents.y / 2;
    expect(top, lessThan(centreAtWall + half));
  });

  test('turned side-on, the whole board fits a phone, from inside the hall',
      () {
    // The board is wider than any portrait screen can show face-on from in
    // the hall; dragging round it brings its short side across the screen.
    final depth = KeyboardLayout.boardDepth * KeyboardLayout.scale;
    for (final elevation in <double>[
      KeyboardOrbit.minElevation,
      GalleryCameraPath.hallRestElevation,
      KeyboardOrbit.maxElevation,
    ]) {
      for (final MapEntry(key: name, value: aspect) in phones.entries) {
        final side = GalleryCameraPath.orbitPose(
          math.pi / 2,
          elevation,
          aspect: aspect,
        );
        final distance = (side.position - side.target).length;
        expect(
          depth * 1.04,
          lessThan(2 * halfWidth(aspect) * distance),
          reason: '$name at elevation $elevation',
        );
      }
    }
  });

  test('the camera stays inside the hall all the way round', () {
    for (var a = 0.0; a < 2 * math.pi; a += math.pi / 12) {
      for (final e in <double>[
        KeyboardOrbit.minElevation,
        KeyboardOrbit.maxElevation,
      ]) {
        for (final aspect in <double>[...phones.values, 16 / 9]) {
          final pose = GalleryCameraPath.orbitPose(a, e, aspect: aspect);
          expect(insideHall(pose.position), isTrue,
              reason: 'azimuth $a, elevation $e, aspect $aspect');
        }
      }
    }
  });

  test('a wide screen keeps the hall as it was', () {
    expect(GalleryCameraPath.hallViewDistanceFor(16 / 9), 3.5);
    expect(
      GalleryCameraPath.hallOrbitRadiusFor(16 / 9),
      closeTo(GalleryCameraPath.hallOrbitRadius, 1e-9),
    );
  });

  test('the approach hands over to the orbit where it stops, at any aspect',
      () {
    for (final aspect in <double>[...phones.values, 16 / 9]) {
      final end = GalleryCameraPath.poseAt(1, aspect: aspect);
      final orbit = GalleryCameraPath.orbitPose(
        0,
        GalleryCameraPath.hallRestElevation,
        aspect: aspect,
      );
      expect((end.position - orbit.position).length, lessThan(1e-4),
          reason: '$aspect');
    }
  });
}
