import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/gallery_camera_path.dart';

void main() {
  group('when the board starts to rise', () {
    test('revealBegins is the first position it actually moves at', () {
      const epsilon = 1e-3;

      // The sound of the board arriving hangs off this. A threshold that
      // sits earlier plays it while the visitor is still walking to the
      // doorway, describing something that has not happened.
      //
      // `closeTo` rather than exactly zero: the position is arrived at by
      // arithmetic on shares of shares, so it lands a rounding error either
      // side of the point rather than on it.
      expect(
        GalleryCameraPath.revealAt(GalleryCameraPath.revealBegins),
        closeTo(0, 1e-9),
      );
      expect(
        GalleryCameraPath.revealAt(GalleryCameraPath.revealBegins + epsilon),
        greaterThan(1e-3),
      );
      expect(
        GalleryCameraPath.revealAt(GalleryCameraPath.revealBegins - epsilon),
        0,
      );
    });

    test('it is well after the hall is entered', () {
      // The mistake it replaced: `panEnd` is where the *hall* begins, and
      // the board waits a third of the way through it before moving.
      expect(
        GalleryCameraPath.revealBegins,
        greaterThan(GalleryCameraPath.panEnd),
      );
      expect(
        GalleryCameraPath.revealBegins - GalleryCameraPath.panEnd,
        greaterThan(0.05),
      );
    });

    test('and before the walk is over', () {
      expect(GalleryCameraPath.revealBegins, lessThan(1));
      expect(GalleryCameraPath.revealAt(1), 1);
    });
  });
}
