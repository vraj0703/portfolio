import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/presentation/game/backdrop_component.dart';
import 'package:portfolio/presentation/game/rehearsal_pass.dart';

void main() {
  tearDown(() => RehearsalPass.active = false);

  test(
    'full strength only on the rehearsal pass, while the scene rehearses',
    () {
      // Drawing in full on every frame under the loading screen doubled
      // loading on the ROG (ms_ready ~25 s to ~57 s): only the pixel's pass.
      RehearsalPass.active = true;
      expect(RehearsalPass.strength(rehearsing: true, otherwise: 0), 1);
      expect(RehearsalPass.strength(rehearsing: false, otherwise: 0.3), 0.3);

      RehearsalPass.active = false;
      expect(RehearsalPass.strength(rehearsing: true, otherwise: 0), 0);
      expect(RehearsalPass.strength(rehearsing: true, otherwise: 0.7), 0.7);
    },
  );

  test('off unless the pass is being drawn', () {
    expect(RehearsalPass.active, isFalse);
  });

  test('the backdrop draws both paths only on the pass', () {
    // The component hands passesFor its rule AND the pass.
    expect(BackdropComponent.passesFor(rehearsing: false, opacity: 0), isEmpty);
  });
}
