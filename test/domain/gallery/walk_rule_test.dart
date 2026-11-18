import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/config/button_flags.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';

void main() {
  test('the stick walks the gallery, on by default, off by its flag', () {
    expect(const ButtonFlags().walkStick, isTrue);
    expect(const SceneState.gallery().walksByStick, isTrue);
    expect(
      const SceneState.gallery(
        flags: ButtonFlags(walkStick: false),
      ).walksByStick,
      isFalse,
    );
  });

  test('and only in the gallery', () {
    for (final state in <SceneState>[
      const SceneState.loading(),
      const SceneState.title(),
      const SceneState.active(),
      const SceneState.contact(),
    ]) {
      expect(state.walksByStick, isFalse, reason: '$state');
    }
  });

  test('the flag is part of equality, so a change reaches the view', () {
    expect(const ButtonFlags(walkStick: false), isNot(const ButtonFlags()));
  });
}
