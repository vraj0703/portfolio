import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/utils/scroll_driver.dart';

void main() {
  ScrollDriver atTheEnd() {
    final driver = ScrollDriver(
      extent: 8000,
      progressExtent: 8000,
      snapPoints: const <double>[],
    );
    driver.scrollBy(99999);
    for (var i = 0; i < 60 * 30; i++) {
      driver.update(1 / 60);
    }
    return driver;
  }

  test('progress never actually reaches one', () {
    // Worth pinning, because it is not what anyone assumes. The driver closes
    // on its target with an exponential spring, so the gap halves for ever
    // and never becomes nothing: after thirty seconds of settling the
    // progress is 0.9999999999999996.
    //
    // Anything gated on `progress >= 1` is therefore unreachable. That is not
    // hypothetical — it is what made the skills keyboard completely inert:
    // both turning the board and pressing a key were behind exactly that
    // condition, and neither ever became possible.
    final driver = atTheEnd();

    expect(driver.progress, lessThan(1));
    expect(driver.progress, greaterThan(0.999));
  });

  test('the stage still knows when it is spent', () {
    // The right question to ask of a spring is whether the *target* has run
    // out, not whether the position has caught up with it.
    expect(atTheEnd().isComplete, isTrue);
  });
}
