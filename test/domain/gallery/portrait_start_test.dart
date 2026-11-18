import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/gallery_camera_path.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';
import 'package:portfolio/domain/gallery/gallery_shape.dart';

/// Whether [piece] is inside the camera's horizontal field of view at the
/// start of the walk, for a screen of [aspect] (width over height).
bool inViewAtStart(Placement piece, GalleryShape shape, double aspect) {
  final pose = GalleryCameraPath.poseAt(0, aspect: aspect);
  final ahead = (pose.target - pose.position)..y = 0;
  final toPiece = (piece.position - pose.position)..y = 0;
  final angle = math.acos(
    ahead.normalized().dot(toPiece.normalized()).clamp(-1.0, 1.0),
  );
  final halfWidth = math.atan(math.tan(shape.fovRadians / 2) * aspect);
  return angle < halfWidth;
}

void main() {
  group('the BACK sign and the radio are in view on arrival', () {
    const phone = 1080 / 2005; // the ROG's gallery view, at DPR 2
    const laptop = 16 / 9;

    Placement entrance(GalleryShape shape, SurfaceKind kind) =>
        GalleryLayout.build(
          shape: shape,
        ).firstWhere((p) => p.kind == kind && p.position.z > -2);

    test(
      'a portrait phone now starts far enough back to see both on arrival',
      () {
        // From the old start (z = 3) they sat 39 degrees off the corridor's
        // line and a portrait camera sees ~24 either side, so neither was
        // ever on screen (Vishal's phone). The portrait walk now starts at
        // portraitStartZ, where both are in view.
        const shape = GalleryShape.portrait;
        for (final kind in <SurfaceKind>[
          SurfaceKind.exitSign,
          SurfaceKind.radio,
        ]) {
          expect(
            inViewAtStart(entrance(shape, kind), shape, phone),
            isTrue,
            reason: '$kind',
          );
        }
        expect(
          GalleryCameraPath.startZFor(phone),
          GalleryCameraPath.portraitStartZ,
        );
        expect(GalleryCameraPath.startZFor(laptop), GalleryCameraPath.startZ);
      },
    );

    test('a laptop sees both from the usual start', () {
      const shape = GalleryShape.desktop;
      for (final kind in <SurfaceKind>[
        SurfaceKind.exitSign,
        SurfaceKind.radio,
      ]) {
        expect(
          inViewAtStart(entrance(shape, kind), shape, laptop),
          isTrue,
          reason: '$kind',
        );
      }
    });
  });
}
