import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/gallery_dimensions.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';
import 'package:portfolio/domain/gallery/gallery_lighting.dart';
import 'package:portfolio/domain/gallery/gallery_shape.dart';
import 'package:portfolio/domain/gallery/project_focus.dart';

/// The corridor's shape keyed on the screen's aspect.
void main() {
  const phones = <double>[9 / 21, 9 / 20, 9 / 19.5, 412 / 915, 9 / 16];

  test('a laptop gets today\'s corridor exactly', () {
    const d = GalleryShape.desktop;
    expect(GalleryShape.forAspect(16 / 9), same(d));
    expect(GalleryShape.forAspect(1), same(d));
    expect(d.corridorWidth, GalleryDimensions.corridorWidth);
    expect(d.wallX, GalleryDimensions.wallX);
    expect(d.ceilY, GalleryDimensions.ceilY);
    expect(d.fovRadians, closeTo(GalleryDimensions.fovRadians, 1e-12));
  });

  test('the desktop layout and lights are unchanged by the parameter', () {
    final before = GalleryLayout.build();
    final after = GalleryLayout.build(shape: GalleryShape.desktop);
    expect(after.length, before.length);
    for (var i = 0; i < before.length; i++) {
      expect(after[i].position, before[i].position);
      expect(after[i].extents, before[i].extents);
    }
    final l0 = GalleryLighting.build();
    final l1 = GalleryLighting.build(shape: GalleryShape.desktop);
    for (var i = 0; i < l0.length; i++) {
      expect(l1[i].position, l0[i].position);
    }
  });

  test('a phone gets a narrower, lower corridor and a wider lens', () {
    const p = GalleryShape.portrait;
    for (final a in phones) {
      expect(GalleryShape.forAspect(a), same(p));
    }
    expect(p.corridorWidth, lessThan(GalleryDimensions.corridorWidth));
    expect(p.ceilY, lessThan(GalleryDimensions.ceilY));
    expect(p.fovRadians, greaterThan(GalleryDimensions.fovRadians));
  });

  test('on a phone every frame hangs on the narrower walls', () {
    const p = GalleryShape.portrait;
    final frames = GalleryLayout.build(
      shape: p,
    ).where((piece) => piece.kind == SurfaceKind.frame);
    expect(frames, isNotEmpty);
    for (final f in frames) {
      expect(f.position.x.abs(), lessThan(p.wallX));
      expect(f.position.x.abs(), greaterThan(p.wallX - 0.5));
    }
  });

  test('on every phone, focusing a frame keeps the camera inside the room', () {
    const p = GalleryShape.portrait;
    final frames = GalleryLayout.build(
      shape: p,
    ).where((piece) => piece.kind == SurfaceKind.frame);
    for (final a in phones) {
      for (final f in frames) {
        final pose = ProjectFocus.poseFor(f, aspect: a, shape: p);
        expect(
          ProjectFocus.fitsInside(pose, shape: p),
          isTrue,
          reason:
              'aspect $a, frame at ${f.position}: camera at '
              '${pose.position.x.toStringAsFixed(2)}, wall at ${p.wallX}',
        );
      }
    }
  });

  test('the lights hang from the lower ceiling on a phone', () {
    final desk = GalleryLighting.build();
    final phone = GalleryLighting.build(shape: GalleryShape.portrait);
    double highest(List<LightPlacement> ls) =>
        ls.map((l) => l.position.y).reduce((a, b) => a > b ? a : b);
    expect(highest(phone), lessThan(highest(desk)));
    expect(highest(phone), lessThan(GalleryShape.portrait.ceilY));
  });
}
