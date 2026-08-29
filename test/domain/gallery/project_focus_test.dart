import 'package:flutter_test/flutter_test.dart';
import 'dart:math' as math;

import 'package:portfolio/domain/gallery/control_layout.dart';
import 'package:portfolio/domain/gallery/gallery_dimensions.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';
import 'package:portfolio/domain/gallery/project_focus.dart';

void main() {
  final frames = GalleryLayout.build()
      .where((p) => p.kind == SurfaceKind.frame)
      .toList();

  // Laptop, portrait phone, and an ultrawide — the fit is governed by height
  // on one and by width on another, and only checking both catches it.
  const aspects = <double>[16 / 9, 9 / 16, 21 / 9];

  group('framing a piece of work', () {
    test('the camera stands in the corridor, not inside the wall', () {
      for (final aspect in aspects) {
        for (final frame in frames) {
          final pose = ProjectFocus.poseFor(frame, aspect: aspect);

          expect(
            ProjectFocus.fitsInside(pose),
            isTrue,
            reason: 'at aspect $aspect the shot needs more room than the '
                'corridor has, so the camera ends up behind the far wall',
          );
        }
      }
    });

    test('it steps away from the wall the work hangs on', () {
      for (final frame in frames) {
        final pose = ProjectFocus.poseFor(frame, aspect: 16 / 9);

        // Stepping the wrong way is the sign error that puts the camera
        // inside the plaster, looking at the back of the piece.
        expect(pose.position.x.abs(), lessThan(frame.position.x.abs()));
      }
    });

    test('it looks square on, not along the corridor', () {
      // A raking view of a flat plane of text is a view nobody can read.
      for (final frame in frames) {
        final pose = ProjectFocus.poseFor(frame, aspect: 16 / 9);

        expect(pose.target.z, closeTo(pose.position.z, 1e-5));
        expect(pose.target.y, closeTo(pose.position.y, 1e-5));
      }
    });

    test('it frames the work, and each one the same way', () {
      final distances = frames
          .map(
            (f) => (ProjectFocus.poseFor(f, aspect: 16 / 9).position.x -
                    f.position.x)
                .abs(),
          )
          .toSet();

      expect(
        distances.map((d) => d.toStringAsFixed(4)).toSet(),
        hasLength(1),
        reason: 'the pieces are the same size, so a visitor stepping between '
            'them should not find the shot changing scale',
      );
    });
  });

  test('the controls are inside the shot, not below it', () {
    // The bug this exists for: the controls rendered correctly, on the wall,
    // in the right place — 0.35 units under the bottom edge of the framing,
    // where nobody could see them. A shot composed on the work alone crops
    // off everything hung beneath it.
    for (final aspect in aspects) {
      for (final frame in frames) {
        final pose = ProjectFocus.poseFor(frame, aspect: aspect);
        final distance = (pose.position.x - frame.position.x).abs();
        final halfHeight =
            distance * math.tan(GalleryDimensions.fovRadians / 2);
        final lowestVisible = pose.target.y - halfHeight;

        final controls = ControlLayout.below(
          frame,
          canGoBack: true,
          canGoForward: true,
        );

        for (final control in controls) {
          expect(
            control.position.y - ControlLayout.iconSize / 2,
            greaterThan(lowestVisible),
            reason: 'at aspect \$aspect the ${control.action.name} control '
                'falls off the bottom of the shot',
          );
        }
      }
    }
  });

  test('the work itself still fits', () {
    // Reaching lower must not push the frame off the top.
    for (final aspect in aspects) {
      for (final frame in frames) {
        final pose = ProjectFocus.poseFor(frame, aspect: aspect);
        final distance = (pose.position.x - frame.position.x).abs();
        final halfHeight =
            distance * math.tan(GalleryDimensions.fovRadians / 2);

        expect(
          pose.target.y + halfHeight,
          greaterThan(frame.position.y + frame.extents.y / 2),
          reason: 'the top of the work is cropped',
        );
      }
    }
  });

  group('the fit', () {
    test('a narrower viewport needs more room, not less', () {
      // The failure this guards: fitting only the height looks right on the
      // machine it was written on and crops the sides everywhere else.
      final wide = ProjectFocus.distanceFor(
        width: 4,
        height: 3,
        aspect: 21 / 9,
      );
      final narrow = ProjectFocus.distanceFor(
        width: 4,
        height: 3,
        aspect: 9 / 16,
      );

      expect(narrow, greaterThan(wide));
    });

    test('never closer than the standoff', () {
      // A camera that fits a tiny piece by standing inside its frame shows
      // nothing: whatever is nearer than the near plane is clipped away.
      expect(
        ProjectFocus.distanceFor(width: 0.01, height: 0.01, aspect: 16 / 9),
        ProjectFocus.minimumStandoff,
      );
    });

    test('leaves a margin around the work', () {
      final exact =
          (GalleryDimensions.frameMaxHeight / 2) /
          (ProjectFocus.distanceFor(
                width: 0,
                height: GalleryDimensions.frameMaxHeight,
                aspect: 16 / 9,
              ) *
              1);

      // Fitting edge to edge reads as a crop rather than a composition.
      expect(exact, lessThan(0.5773), reason: 'tan(65deg/2) with no margin');
    });
  });
}
