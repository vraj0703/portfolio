import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/walk_order.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';

void main() {
  final order = WalkOrder(GalleryLayout.build());
  final frames = order.frames;

  test('every piece is in the order, exactly once', () {
    final ids = frames.map((f) => f.project!.id).toSet();

    expect(frames, hasLength(7));
    expect(ids, hasLength(7), reason: 'a duplicate would be unreachable');
  });

  test('the order is the order the visitor walks past them', () {
    // Not the declaration order, and not one wall then the other. Stepping
    // "next" must never jump backwards down the corridor.
    for (var i = 1; i < frames.length; i++) {
      expect(
        frames[i].position.z,
        lessThanOrEqualTo(frames[i - 1].position.z),
        reason: 'piece $i sits nearer the entrance than the one before it',
      );
    }
  });

  test('facing pairs are read left then right', () {
    // Two pieces at the same depth face each other. Without a tie-break the
    // pair's order depends on declaration order, which is invisible here and
    // changes when the data is reordered.
    for (var i = 1; i < frames.length; i++) {
      if (frames[i].position.z != frames[i - 1].position.z) continue;
      expect(frames[i - 1].position.x, lessThan(frames[i].position.x));
    }
  });

  group('stepping stays on one wall', () {
    test('never crosses the corridor', () {
      // Crossing swings the camera through a hundred and eighty degrees to
      // face the wall behind where the visitor was standing, which loses
      // them completely.
      for (final frame in frames) {
        for (final step in <Placement?>[
          order.previous(frame),
          order.next(frame),
        ]) {
          if (step == null) continue;
          expect(
            step.position.x.isNegative,
            frame.position.x.isNegative,
            reason: 'stepped from one wall to the other',
          );
        }
      }
    });

    test('the ends of each wall close', () {
      for (final side in <bool>[true, false]) {
        final wall = frames
            .where((f) => f.position.x.isNegative == side)
            .toList();

        expect(order.hasPrevious(wall.first), isFalse);
        expect(order.hasNext(wall.last), isFalse);
      }
    });

    test('the ends do not wrap', () {
      // Wrapping would leave both arrows showing forever, so a visitor
      // stepping through a wall would arrive back at its start with nothing
      // telling them they had seen it all.
      for (final side in <bool>[true, false]) {
        final wall = frames
            .where((f) => f.position.x.isNegative == side)
            .toList();

        expect(order.previous(wall.first), isNull);
        expect(order.next(wall.last), isNull);
      }
    });

    test('stepping forward then back returns to where you were', () {
      for (final frame in frames) {
        final forward = order.next(frame);
        if (forward == null) continue;

        expect(order.previous(forward)?.project?.id, frame.project!.id);
      }
    });

    test('stepping forward reaches every piece on that wall', () {
      // The arrows are the only way to compare two pieces without re-walking
      // the corridor, so a break anywhere strands the rest of the wall.
      for (final side in <bool>[true, false]) {
        final wall = frames
            .where((f) => f.position.x.isNegative == side)
            .toList();

        var current = wall.first;
        final seen = <String>{current.project!.id};

        while (order.hasNext(current)) {
          current = order.next(current)!;
          expect(seen.add(current.project!.id), isTrue, reason: 'revisited');
        }

        expect(seen, hasLength(wall.length));
      }
    });
  });

  test('nearest finds the piece the visitor is standing at', () {
    for (final frame in frames) {
      expect(
        order.nearestTo(frame.position.z).position.z,
        frame.position.z,
      );
    }
  });
}
