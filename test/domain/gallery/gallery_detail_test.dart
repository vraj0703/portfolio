import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/gallery_detail.dart';

void main() {
  test('desktops and tablets render the corridor at full size', () {
    expect(GalleryDetail.forDevice(phone: false), same(GalleryDetail.full));
    expect(GalleryDetail.full.renderScale, 1);
  });

  test('phones render it at half size: fill rate is the cost there', () {
    expect(GalleryDetail.forDevice(phone: true), same(GalleryDetail.phone));
    expect(GalleryDetail.phone.renderScale, 0.5);
  });

  test('the scene builder applies it, chosen by the browser', () {
    final source = File(
      'lib/presentation/gallery/gallery_scene_builder.dart',
    ).readAsStringSync();
    expect(source, contains('..renderScale = GalleryDetail.forDevice('));
    expect(source, contains('phone: Browser.isPhone()'));
  });
}
