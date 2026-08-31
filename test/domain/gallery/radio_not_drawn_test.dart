import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';

void main() {
  test('the radio and its controls are not ordinary surfaces', () {
    // The scene builder draws every placement it does not recognise as a
    // cuboid in the wall's own material. The radio draws its own face and
    // its controls are tap targets rather than objects, so all three landing
    // in that branch put boxes exactly where the face is — two coplanar
    // surfaces with equal claim to the same pixels, which resolve
    // differently frame to frame and read as the buttons flickering.
    //
    // Stated here because the builder needs a GPU and this does not: what is
    // checkable without one is that these kinds exist to be skipped.
    const drawnElsewhere = <SurfaceKind>{
      SurfaceKind.radio,
      SurfaceKind.radioPlay,
      SurfaceKind.radioNext,
    };

    final present = GalleryLayout.build()
        .map((piece) => piece.kind)
        .toSet()
        .intersection(drawnElsewhere);

    expect(
      present,
      drawnElsewhere,
      reason: 'a radio kind vanished; the builder still skips it',
    );
  });
}
