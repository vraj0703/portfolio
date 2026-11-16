import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/config/title_config.dart';

/// The name on the title screen fits the screen it is on.
void main() {
  // "VISHAL RAJ" at its designed size: 56pt with 28pt tracking runs to about
  // six hundred pixels.
  const natural = 600.0;

  test('a laptop shows the name at its designed size', () {
    expect(
      TitleConfig.primaryFit(naturalWidth: natural, viewportWidth: 1440),
      1,
    );
  });

  for (final phone in <double>[390, 360]) {
    test('a $phone wide phone shrinks it inside the edges', () {
      final fit = TitleConfig.primaryFit(
        naturalWidth: natural,
        viewportWidth: phone,
      );

      expect(fit, lessThan(1));
      expect(
        natural * fit,
        lessThanOrEqualTo(phone * TitleConfig.primaryMaxWidthShare + 1e-9),
        reason: 'the name runs off a $phone wide screen',
      );
    });
  }

  test('nothing measured yet leaves it alone', () {
    // Before the first resize the width is zero; the fit must not divide by
    // it or collapse the name.
    expect(TitleConfig.primaryFit(naturalWidth: natural, viewportWidth: 0), 1);
    expect(TitleConfig.primaryFit(naturalWidth: 0, viewportWidth: 390), 1);
  });
}
