import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/audio/app_audio.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';

import '../../support/scene_harness.dart';

/// Comfortably past the wait between arriving and the music starting.
final Duration afterTheWait = AudioCue.galleryEntry.length * 2;

/// Runs [body] against a scene bloc with a radio it can watch.
///
/// On a moved clock rather than a waited-out one. What is under test is a
/// *timer* — the pause between arriving in the corridor and the music
/// starting — and seven of those at two and a quarter seconds each would be
/// fifteen seconds of a run spent doing nothing.
void withRadio(void Function(FakeAsync clock, SceneBloc bloc, RecordingRadio radio) body) {
  fakeAsync((clock) {
    final radio = RecordingRadio();
    final bloc = SceneBloc(radio: radio);

    body(clock, bloc, radio);

    bloc.close();
    radio.dispose();
    clock.flushMicrotasks();
  });
}

void main() {
  group('the radio belongs to the gallery and to nothing else', () {
    test('and comes on only once the room has announced itself', () {
      withRadio((clock, bloc, radio) {
        bloc.emit(const SceneState.gallery());
        clock.flushMicrotasks();

        expect(
          radio.calls,
          isEmpty,
          reason: 'the music started underneath the gallery entry sound',
        );

        clock.elapse(afterTheWait);
        expect(radio.calls, <String>['play']);
      });
    });

    test('never on the screens with no radio on the wall', () {
      // The failure this catches is silent: a stage that forgets to switch
      // the radio off leaves a stream playing under a title screen, and
      // nothing in the code that added the stage looks wrong.
      for (final state in <SceneState>[
        const SceneState.logo(),
        const SceneState.logoOverlayRemoving(),
        const SceneState.titleLoading(),
        const SceneState.title(),
        const SceneState.active(),
        const SceneState.contact(),
      ]) {
        withRadio((clock, bloc, radio) {
          bloc.emit(state);
          clock.elapse(afterTheWait);

          expect(radio.calls, isEmpty, reason: '$state put the radio on air');
        });
      }
    });

    test('stepping back out of the corridor takes it off air', () {
      withRadio((clock, bloc, radio) {
        bloc.emit(const SceneState.gallery());
        clock.elapse(afterTheWait);
        expect(radio.calls, <String>['play']);

        bloc.add(const SceneEvent.galleryExited());
        clock.flushMicrotasks();
        expect(radio.calls, <String>['play', 'stop']);
      });
    });

    test('and so does following the invitation to the contact screen', () {
      // The other way out. Two exits and one rule — which is the reason the
      // radio follows the state instead of being switched off at each door.
      withRadio((clock, bloc, radio) {
        bloc.emit(const SceneState.gallery());
        clock.elapse(afterTheWait);

        bloc.add(const SceneEvent.contactRequested());
        clock.flushMicrotasks();
        expect(radio.calls, <String>['play', 'stop']);
      });
    });

    test('leaving during the wait cancels it rather than firing late', () {
      // The bug this exists for: a timer set on arrival outlives the screen
      // that set it, so the music would come on over whatever the visitor
      // moved to, a second and a half after they left.
      withRadio((clock, bloc, radio) {
        bloc.emit(const SceneState.gallery());
        clock.elapse(const Duration(milliseconds: 200));

        bloc.add(const SceneEvent.contactRequested());
        clock.elapse(afterTheWait);

        expect(
          radio.calls,
          isEmpty,
          reason: 'the wait fired after the visitor had gone',
        );
      });
    });

    test('coming back to the corridor puts it on again', () {
      withRadio((clock, bloc, radio) {
        bloc.emit(const SceneState.gallery());
        clock.elapse(afterTheWait);

        bloc.emit(const SceneState.contact());
        clock.flushMicrotasks();
        expect(radio.calls, <String>['play', 'stop']);

        bloc.emit(const SceneState.gallery());
        clock.elapse(afterTheWait);
        expect(radio.calls, <String>['play', 'stop', 'play']);
      });
    });

    test('and re-entering does not stack a second wait on the first', () {
      // `Gallery` carries no fields, so re-emitting it is not a change and
      // never reaches the rule. This covers the case where something later
      // gives it one.
      withRadio((clock, bloc, radio) {
        bloc.emit(const SceneState.gallery());
        clock.elapse(const Duration(milliseconds: 100));
        bloc.emit(const SceneState.gallery());
        clock.elapse(afterTheWait);

        expect(radio.calls, <String>['play']);
      });
    });

    test('and closing the scene leaves nothing playing', () {
      fakeAsync((clock) {
        final radio = RecordingRadio();
        final bloc = SceneBloc(radio: radio);

        bloc.emit(const SceneState.gallery());
        clock.elapse(afterTheWait);

        bloc.close();
        clock.flushMicrotasks();
        expect(radio.calls.last, 'stop');

        radio.dispose();
        clock.flushMicrotasks();
      });
    });
  });

  group('which screens have a radio on them', () {
    test('the gallery, which is the corridor and the hall together', () {
      // One state covers both rooms — the hall is walked to, not navigated
      // to — so both walls with a radio on them are the same answer.
      expect(const SceneState.gallery().playsRadio, isTrue);
    });

    test('and none of the others', () {
      for (final state in <SceneState>[
        const SceneState.loading(),
        const SceneState.logo(),
        const SceneState.logoOverlayRemoving(),
        const SceneState.titleLoading(),
        const SceneState.title(),
        const SceneState.active(),
        const SceneState.contact(),
      ]) {
        expect(state.playsRadio, isFalse, reason: '$state claims a radio');
      }
    });
  });
}
