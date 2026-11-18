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

  test('baked, the builder hangs no live lamp and gives the floor the map', () {
    final source = File(
      'lib/presentation/gallery/gallery_scene_builder.dart',
    ).readAsStringSync();
    expect(source, contains('if (!detail.bakeLighting) _light(scene, shape);'));
    expect(source, contains('..lightmapTexture = floorLightmap.texture'));
    expect(source, contains('..lightmapRgbm = true'));
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
