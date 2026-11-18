import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/gallery_detail.dart';

void main() {
  test('desktops and tablets render the corridor at full size', () {
    expect(GalleryDetail.forDevice(phone: false), same(GalleryDetail.full));
    expect(GalleryDetail.full.renderScale, 1);
    expect(GalleryDetail.full.bakeLighting, isFalse);
  });

  test('phones render it at half size: fill rate is the cost there', () {
    expect(GalleryDetail.forDevice(phone: true), same(GalleryDetail.phone));
    expect(GalleryDetail.phone.renderScale, 0.5);
    expect(GalleryDetail.phone.bakeLighting, isTrue);
  });

  test('baked, the builder hangs no live lamp and maps every lit surface', () {
    final source = File(
      'lib/presentation/gallery/gallery_scene_builder.dart',
    ).readAsStringSync();
    expect(source, contains('if (!detail.bakeLighting) _light(scene, shape);'));
    expect(source, contains('..lightmapRgbm = true'));
    // Floor and ceiling by region, walls by their room-facing side, and the
    // small lit things one texel each.
    expect(source, contains('SurfaceKind.floor => _bakeLevel('));
    expect(source, contains('SurfaceKind.ceiling => _bakeLevel('));
    expect(source, contains('_ => _bakeFace(piece, lamps)'));
    expect(
      source,
      contains('if (lamps != null) _bakeTheRest(scene.root, lamps);'),
    );
  });

  test('the scene builder applies it, chosen by the browser', () {
    final source = File(
      'lib/presentation/gallery/gallery_scene_builder.dart',
    ).readAsStringSync();
    expect(
      source,
      contains('GalleryDetail.forDevice(phone: Browser.isPhone())'),
    );
    expect(source, contains('..renderScale = detail.renderScale'));
  });
}
