import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/gallery_dimensions.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';

void main() {
  final pieces = GalleryLayout.build();

  Iterable<Placement> of(SurfaceKind kind) =>
      pieces.where((p) => p.kind == kind);

  /// The one by the corridor's entrance, as opposed to the hall's.
  Placement corridorRadio() => of(SurfaceKind.radio)
      .firstWhere((p) => p.position.x < GalleryDimensions.wallX);

  group('the radio on the wall', () {
    test('there are two of them, each with two things to press', () {
      // One by the corridor's entrance and one in the skills hall. Same
      // player, same state, two faces.
      expect(of(SurfaceKind.radio), hasLength(2));
      expect(of(SurfaceKind.radioPlay), hasLength(2));
      expect(of(SurfaceKind.radioNext), hasLength(2));
    });

    test('the hall radio sits opposite the invitation, across the door', () {
      final hall = of(SurfaceKind.radio)
          .firstWhere((p) => p.position.x > GalleryDimensions.wallX);
      final invitation = of(SurfaceKind.connectSign).single;

      // Both on the hall's entry wall, one either side of the way in.
      expect(hall.position.x, closeTo(invitation.position.x, 0.01));
      expect(
        (hall.position.z - GalleryDimensions.kbZ).sign,
        -(invitation.position.z - GalleryDimensions.kbZ).sign,
        reason: 'both ended up on the same side of the door',
      );

      // Level by what is written on them, not by the panels they are
      // written on. The invitation is a single line, so its panel's middle
      // *is* its text; the radio is four rows centred as a block, so its
      // panel's middle falls between the status and the controls. Hanging
      // the two panels at one height therefore lines up nothing anybody
      // looks at — which is exactly how this read in the hall.
      final nameY = hall.position.y + GalleryLayout.radioStationDrop;
      expect(
        nameY,
        closeTo(invitation.position.y, 0.001),
        reason: 'the station name is not level with the invitation',
      );
      expect(
        GalleryLayout.radioStationDrop,
        greaterThan(0),
        reason: 'the name does not sit above the middle of its own face',
      );
    });

    test('the corridor radio is not hung by the same rule', () {
      // It has nothing to pair with — the way out is across the corridor at
      // picture height, and it is the *panel* that mirrors it. Only the hall
      // has two pieces of lettering that have to agree.
      expect(
        corridorRadio().position.y,
        closeTo(GalleryDimensions.frameY, 0.001),
      );
    });

    test('hangs on the right wall, opposite the way out', () {
      final radio = corridorRadio();
      final exit = of(SurfaceKind.exitSign).single;

      // One object each side of the entrance, at the same height, so the
      // corridor opens with a pair rather than something lopsided.
      expect(radio.position.x, greaterThan(0));
      expect(exit.position.x, lessThan(0));
      expect(radio.position.y, exit.position.y);
      expect(radio.position.z, exit.position.z);
    });

    test('faces into the corridor', () {
      // The opposite quarter turn to the way out: the two walls face each
      // other, so lettering on them cannot share a rotation.
      final radio = corridorRadio();
      final exit = of(SurfaceKind.exitSign).single;

      expect(radio.rotationY, -exit.rotationY);
    });

    test('sits clear of the first picture', () {
      // Pictures start a full spacing in. The radio has the wall before them
      // to itself, or it would be read across a frame.
      final radio = corridorRadio();
      final firstFrame = pieces
          .where((p) => p.kind == SurfaceKind.frame && p.position.x > 0)
          .map((p) => p.position.z)
          .reduce((a, b) => a > b ? a : b);

      expect(radio.position.z, greaterThan(firstFrame));
    });
  });

  group('where a finger has to land', () {
    final play = of(SurfaceKind.radioPlay).first;
    final next = of(SurfaceKind.radioNext).first;

    test('both targets are on the face, not beside it', () {
      final radio = corridorRadio();
      final halfWidth = radio.extents.x / 2;
      final halfHeight = radio.extents.y / 2;

      for (final control in <Placement>[play, next]) {
        expect(
          (control.position.z - radio.position.z).abs(),
          lessThan(halfWidth),
          reason: 'a control hangs off the side of the face',
        );
        expect(
          (control.position.y - radio.position.y).abs(),
          lessThan(halfHeight),
          reason: 'a control hangs off the top or bottom',
        );
      }
    });

    test('and they do not overlap each other', () {
      // The previous site had exactly this bug: the stop control's plane
      // overlapped next, so stopping the radio changed the station.
      final gap = (play.position.z - next.position.z).abs();
      expect(gap, greaterThan(play.extents.x));
    });

    test('are larger than the words drawn on them', () {
      // Read at an angle from across a corridor. A target the size of its
      // own label has to be aimed at.
      expect(play.extents.x, greaterThan(0.3));
      expect(play.extents.y, greaterThan(0.3));
    });
  });
}
