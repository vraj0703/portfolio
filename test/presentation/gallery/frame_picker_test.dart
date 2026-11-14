import 'dart:ui' show Offset, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';
import 'package:portfolio/presentation/gallery/frame_picker.dart';
import 'package:portfolio/presentation/gallery/scene_axes.dart';
import 'package:vector_math/vector_math.dart';

void main() {
  final pieces = GalleryLayout.build();
  final frames = pieces.where((p) => p.kind == SurfaceKind.frame).toList();
  const viewSize = Size(1200, 800);

  /// A stand-in camera at the corridor entrance looking down it.
  ///
  /// Deliberately crude — the point is not to reproduce a perspective camera
  /// but to give the picker a projection whose answers are known, so a wrong
  /// hit is a failure of the picking rather than of the maths behind it.
  Offset? project(Vector3 world) {
    final depth = -world.z + 4;
    if (depth <= 0.1) return null; // behind the camera
    return Offset(
      viewSize.width / 2 + world.x / depth * 600,
      viewSize.height / 2 - world.y / depth * 600,
    );
  }

  Placement? pick(Offset at, {Vector3? from}) => FramePicker.at(
    at,
    viewSize,
    pieces,
    from ?? Vector3(0, 0.5, 4),
    project,
  );

  test('the centre of a frame picks that frame', () {
    for (final frame in frames) {
      final centre = project(SceneAxes.position(frame.position))!;

      expect(pick(centre)?.project?.id, frame.project!.id);
    }
  });

  test('empty wall between frames picks nothing', () {
    // Halfway between the first two frames on the same wall: plaster, not
    // work. A picker that answers with the nearest frame regardless would
    // send a visitor somewhere they did not click.
    final left = frames.where((f) => f.position.x < 0).toList()
      ..sort((a, b) => b.position.z.compareTo(a.position.z));
    final between = Vector3(
      left.first.position.x,
      left.first.position.y,
      (left[0].position.z + left[1].position.z) / 2,
    );

    expect(pick(project(SceneAxes.position(between))!), isNull);
  });

  test('a frame behind the camera is never picked', () {
    // Its corners have no on-screen projection at all, and inventing one
    // would put a hit target where the visitor sees nothing.
    final behind = pieces
        .where((p) => p.kind == SurfaceKind.frame)
        .map((f) => FramePicker.cornersOf(f))
        .expand((c) => c)
        .map((c) => project(SceneAxes.position(c)))
        .toList();

    expect(behind, isNot(contains(isNull)), reason: 'all in front here');
    expect(pick(const Offset(-500, -500)), isNull);
  });

  test('overlapping frames resolve to the nearer one', () {
    // Down a corridor a far frame is visible past the edge of a near one, so
    // their screen rectangles overlap. Picking the far one sends the visitor
    // to a different piece than the one they clicked.
    final left = frames.where((f) => f.position.x < 0).toList()
      ..sort((a, b) => b.position.z.compareTo(a.position.z));
    final near = left.first;
    final far = left.last;

    final hit = pick(
      project(SceneAxes.position(near.position))!,
      from: SceneAxes.position(Vector3(0, 0.5, 4)),
    );

    expect(hit?.project?.id, near.project!.id);
    expect(hit?.project?.id, isNot(far.project!.id));
  });

  test('a frame is picked across its whole face, not just its centre', () {
    final frame = frames.first;
    final corners = FramePicker.cornersOf(frame)
        .map((c) => project(SceneAxes.position(c))!)
        .toList();

    // A point just inside the top-left corner: still the work, and a picker
    // testing a centre-and-radius would miss it.
    final inside = Offset(
      corners.map((c) => c.dx).reduce((a, b) => a < b ? a : b) + 2,
      corners.map((c) => c.dy).reduce((a, b) => a < b ? a : b) + 2,
    );

    expect(pick(inside)?.project?.id, frame.project!.id);
  });

  group('where a press lands on a frame', () {
    final frame = frames.first;
    final corners = [
      for (final c in FramePicker.cornersOf(frame))
        project(SceneAxes.position(c))!,
    ];
    final left = corners.map((c) => c.dx).reduce((a, b) => a < b ? a : b);
    final right = corners.map((c) => c.dx).reduce((a, b) => a > b ? a : b);
    final top = corners.map((c) => c.dy).reduce((a, b) => a < b ? a : b);
    final bottom = corners.map((c) => c.dy).reduce((a, b) => a > b ? a : b);

    test('as a share of the frame, from its top left', () {
      final at = Offset(
        left + (right - left) * 0.8,
        top + (bottom - top) * 0.25,
      );
      final share = FramePicker.fractionWithin(at, frame, project)!;
      expect(share.dx, closeTo(0.8, 1e-9));
      expect(share.dy, closeTo(0.25, 1e-9));
    });

    test('nothing when it misses the frame', () {
      expect(
        FramePicker.fractionWithin(Offset(right + 5, top), frame, project),
        isNull,
      );
    });
  });

  test('a far-wall frame spans x, the way it hangs', () {
    final wall = pieces.firstWhere(
      (p) => p.kind == SurfaceKind.testimonialFrame,
    );
    final xs = FramePicker.cornersOf(wall).map((c) => c.x).toSet();
    final zs = FramePicker.cornersOf(wall).map((c) => c.z).toSet();
    expect(zs, hasLength(1), reason: 'the frame is flat on the far wall');
    expect(
      xs.reduce((a, b) => a > b ? a : b) - xs.reduce((a, b) => a < b ? a : b),
      closeTo(wall.extents.x, 1e-9),
    );
  });
}
