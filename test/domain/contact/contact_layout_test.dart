import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/config/logo_config.dart';
import 'package:portfolio/domain/contact/contact_layout.dart';

void main() {
  group('the contact links on a phone (PORTFOLIO-29)', () {
    test('desktop and landscape: today\'s row exactly', () {
      for (final (w, h) in <(double, double)>[
        (1280, 800),
        (1920, 1080),
        (915, 412),
      ]) {
        final s = ContactLayout.forScreen(w, h);
        expect(s.arrangement, ContactArrangement.row);
        expect(s.fontScale, 1);
        expect(s.blockWidth, LogoConfig.contactGap(w) * 2);
        expect(s.onPlate, isFalse);
      }
    });

    test(
      'every phone arrangement, 320 to 480 wide: readable and touchable',
      () {
        for (final a in <ContactArrangement>[
          ContactArrangement.wrapped,
          ContactArrangement.list,
          ContactArrangement.columns,
        ]) {
          for (var w = 320.0; w <= 480; w += 10) {
            final s = ContactLayout.forScreen(w, w * 2.1, arrangement: a);
            expect(s.arrangement, a);
            // Text at least 16 px.
            expect(
              ContactLayout.designFontSize * s.fontScale,
              greaterThanOrEqualTo(ContactLayout.minFontSize),
            );
            // Touch targets at least 48 dp.
            expect(s.targetHeight, greaterThanOrEqualTo(48));
            // Inside the screen, with its margins.
            expect(s.blockWidth, lessThanOrEqualTo(w - 32 + 1e-9));
            expect(s.blockWidth, greaterThan(0));
            expect(s.onPlate, isTrue);
          }
        }
      },
    );

    test('a phone ships one of the three', () {
      expect(ContactLayout.phoneArrangement, isNot(ContactArrangement.row));
    });
  });
}
