import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/control_layout.dart';
import 'package:portfolio/domain/gallery/gallery_dimensions.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';

void main() {
  final frames = GalleryLayout.build()
      .where((p) => p.kind == SurfaceKind.frame)
      .toList();
  final left = frames.firstWhere((f) => f.position.x < 0);
  final right = frames.firstWhere((f) => f.position.x > 0);

  List<ControlPlacement> row(Placement f) =>
      ControlLayout.below(f, canGoBack: true, canGoForward: true);

  test('the controls hang beneath the work, clear of its frame', () {
    for (final frame in <Placement>[left, right]) {
      for (final control in row(frame)) {
        expect(
          control.position.y,
          lessThan(frame.position.y - frame.extents.y / 2),
          reason: 'a control overlapping the frame covers the work',
        );
      }
    }
  });

  test('they stand off the wall, on the corridor side', () {
    for (final frame in <Placement>[left, right]) {
      for (final control in row(frame)) {
        // Same sign as the wall, but nearer the middle: any further out and
        // it is inside the plaster.
        expect(control.position.x.abs(), lessThan(frame.position.x.abs()));
        expect(control.position.x.isNegative, frame.position.x.isNegative);
      }
    }
  });

  test('the way back is always the slot nearer the entrance', () {
    // The single rule that makes both walls come out right. The camera reads
    // them from opposite sides, so a fixed screen-side would put the arrow on
    // the wrong side of one of them — as it did before.
    for (final frame in <Placement>[left, right]) {
      final controls = row(frame);
      final back = controls
          .firstWhere((c) => c.action == ControlAction.previous)
          .position
          .z;
      final forward = controls
          .firstWhere((c) => c.action == ControlAction.next)
          .position
          .z;

      expect(back, greaterThan(forward));
    }
  });

  test('the arrows aim along the corridor, not across it', () {
    expect(
      ControlLayout.aimFor(ControlAction.previous),
      -ControlLayout.aimFor(ControlAction.next),
      reason: 'the two directions must be opposite, or both point one way',
    );
    expect(ControlLayout.aimFor(ControlAction.exit), 0);
  });

  test('a closed end drops its control rather than showing a dead one', () {
    final ends = ControlLayout.below(
      left,
      canGoBack: false,
      canGoForward: false,
    );

    expect(ends, hasLength(1));
    expect(ends.single.action, ControlAction.exit);
  });

  test('the controls float clear of the floor', () {
    // Resting on it, a small metal object in a room this dim has nothing
    // behind it to separate it from the tiling and simply gets missed.
    for (final frame in <Placement>[left, right]) {
      for (final control in row(frame)) {
        final lowerEdge = control.position.y - ControlLayout.iconSize / 2;
        expect(
          lowerEdge - GalleryDimensions.floorY,
          greaterThan(0.15),
          reason: 'the control sits on the floor',
        );
      }
    }
  });

  test('the way out is always offered', () {
    for (final back in <bool>[true, false]) {
      for (final forward in <bool>[true, false]) {
        final controls = ControlLayout.below(
          left,
          canGoBack: back,
          canGoForward: forward,
        );
        expect(
          controls.map((c) => c.action),
          contains(ControlAction.exit),
          reason: 'a focused piece with no way out is a trap',
        );
      }
    }
  });
}
