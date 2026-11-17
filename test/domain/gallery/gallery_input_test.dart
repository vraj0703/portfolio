import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/gallery_input.dart';

/// Which way each input walks the corridor. Progress rises going forward.
void main() {
  group('touch', () {
    test('a swipe UP (finger dy < 0) walks forward', () {
      expect(GalleryInput.dragStep(-100), greaterThan(0));
    });

    test('a swipe DOWN walks back', () {
      expect(GalleryInput.dragStep(100), lessThan(0));
    });

    test('at the intro\'s gain', () {
      expect(GalleryInput.dragStep(-50), 100);
    });
  });

  group('wheel and trackpad, unchanged', () {
    test('a scroll delta of +100 steps -100, as it always has', () {
      expect(GalleryInput.wheelStep(100), -100);
      expect(GalleryInput.wheelStep(-100), 100);
    });
  });
}
