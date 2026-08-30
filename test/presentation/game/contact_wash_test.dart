import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/game/contact_dim_component.dart';

/// Drives [component] for [seconds] at sixty frames.
void run(ContactDimComponent component, double seconds) {
  for (var i = 0; i < (seconds * 60).round(); i++) {
    component.update(1 / 60);
  }
}

ContactDimComponent wash(ContactWash wash) =>
    ContactDimComponent(colour: const Color(0xFF000000), wash: wash);

void main() {
  group('which states the room stands back for', () {
    test('the contact screen, and nothing else', () {
      expect(ContactDimComponent.dimsFor(const SceneState.contact()), isTrue);

      for (final other in const <SceneState>[
        SceneState.loading(),
        SceneState.logo(),
        SceneState.logoOverlayRemoving(),
        SceneState.titleLoading(),
        SceneState.title(),
        SceneState.active(),
        SceneState.gallery(),
      ]) {
        expect(ContactDimComponent.dimsFor(other), isFalse, reason: '$other');
      }
    });
  });

  group('the dim', () {
    test('comes up with the contact screen and stays', () {
      final dim = wash(ContactWash.dim)
        ..onInitialState(const SceneState.gallery());
      expect(dim.shown, 0);

      dim.onNewState(const SceneState.contact());
      run(dim, 2);
      expect(dim.shown, 1);

      // Still up a while later: it is what the screen looks like, not
      // something it passes through.
      run(dim, 5);
      expect(dim.shown, 1);
    });

    test('and goes again when the screen does', () {
      final dim = wash(ContactWash.dim)
        ..onInitialState(const SceneState.contact());
      expect(dim.shown, 1);

      dim.onNewState(const SceneState.logoOverlayRemoving());
      run(dim, 2);
      expect(dim.shown, 0);
    });
  });

  group('the arrival veil', () {
    test('is not up on any screen but the one it belongs to', () {
      // The bug this catches, found by reading rather than by looking: the
      // two washes were one flag apart, and off the contact screen the veil
      // read its target as *up* — a black sheet over the whole title stage.
      final veil = wash(ContactWash.arrival)
        ..onInitialState(const SceneState.title());

      expect(veil.shown, 0);
      run(veil, 2);
      expect(veil.shown, 0);
    });

    test('is thrown up on arrival and gets out of the way', () {
      final veil = wash(ContactWash.arrival)
        ..onInitialState(const SceneState.gallery());

      veil.onNewState(const SceneState.contact());
      // Up at once — the corridor handed over through black and this is the
      // same black, still there.
      expect(veil.shown, 1);

      run(veil, 2);
      expect(veil.shown, 0);
    });

    test('is thrown up again on a second visit', () {
      final veil = wash(ContactWash.arrival)
        ..onInitialState(const SceneState.gallery());

      veil.onNewState(const SceneState.contact());
      run(veil, 2);
      expect(veil.shown, 0);

      // Spent after the first visit, the second would appear on a lit screen
      // instead of coming up out of the dark the corridor left.
      veil.onNewState(const SceneState.gallery());
      veil.onNewState(const SceneState.contact());
      expect(veil.shown, 1);
    });
  });
}
