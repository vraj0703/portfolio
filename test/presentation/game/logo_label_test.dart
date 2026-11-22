import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/style/strings.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/game/logo_overlay_component.dart';

import '../../support/scene_harness.dart';

void main() {
  const strings = DefaultAppStrings();

  group('the logo\'s label (PORTFOLIO-30)', () {
    test('a phone reads DOUBLE TAP', () {
      final bloc = SceneBloc();
      addTearDown(bloc.close);
      final overlay = LogoOverlayComponent(
        palette: scenePalette(),
        queuer: bloc,
        touch: true,
      );
      expect(overlay.label, strings.doubleTap);
      expect(strings.doubleTap, 'DOUBLE TAP');
    });

    test('desktop keeps its own wording', () {
      final bloc = SceneBloc();
      addTearDown(bloc.close);
      final overlay = LogoOverlayComponent(
        palette: scenePalette(),
        queuer: bloc,
      );
      expect(overlay.label, strings.tapToEnter);
    });
  });
}
