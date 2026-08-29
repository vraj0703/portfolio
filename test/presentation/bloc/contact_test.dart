import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/game/backdrop_component.dart';
import 'package:portfolio/presentation/game/logo_layer.dart';
import 'package:portfolio/presentation/game/title_layer_component.dart';

import '../../support/scene_journey.dart';

void main() {
  group('reaching the contact screen', () {
    test('the sign in the skills hall opens it', () async {
      final bloc = await inTheGallery();
      expect(bloc.state, isA<Gallery>());

      bloc.add(const SceneEvent.contactRequested());
      await settle();

      expect(bloc.state, isA<Contact>());
      await bloc.close();
    });

    test('the sign is ignored from anywhere but the gallery', () async {
      final bloc = SceneBloc()..add(const SceneEvent.contactRequested());
      await settle();

      // The sign hangs on a wall in a room the visitor is not standing in.
      // A stray event here would drop them onto a contact screen from the
      // loading bar.
      expect(bloc.state, isA<Loading>());
      await bloc.close();
    });
  });

  group('leaving the contact screen', () {
    test('the gallery mark walks back into the corridor', () async {
      final bloc = await onTheContactScreen();

      bloc.add(const SceneEvent.galleryRequested());
      await settle();

      expect(bloc.state, isA<Gallery>());
      await bloc.close();
    });

    test('the home mark leaves the way the visitor came in', () async {
      final bloc = await onTheContactScreen();

      bloc.add(const SceneEvent.homeRequested());
      await settle();

      // The logo screen's own exit, not a jump past it. The contact screen
      // borrows that composition — mark in the middle, ground down, the
      // affordance lit — so leaving it has the same three things to undo,
      // and every one of them is driven by this stage. Emitting
      // `titleLoading` here instead landed on a title with a full-size mark
      // over it and no ground under it.
      expect(bloc.state, isA<LogoOverlayRemoving>());

      bloc.add(const SceneEvent.logoExitCompleted());
      await settle();
      expect(bloc.state, isA<TitleLoading>());

      bloc.add(const SceneEvent.titleEntranceCompleted());
      await settle();
      expect(bloc.state, isA<Title>());

      await bloc.close();
    });

    test('both marks are ignored from anywhere else', () async {
      final bloc = await inTheGallery();

      bloc
        ..add(const SceneEvent.galleryRequested())
        ..add(const SceneEvent.homeRequested());
      await settle();

      expect(bloc.state, isA<Gallery>());
      await bloc.close();
    });
  });

  group('going round by the gallery', () {
    test('the stage is standing again by the time the title arrives',
        () async {
      final bloc = await onTheContactScreen();

      // The route that has no stage of its own to undo anything on: the
      // contact screen puts the mark back in the middle and drops the
      // ground, then hands straight to the gallery, and the sign on the
      // gallery's left wall hands straight back to the title. Nothing in
      // between is the logo screen's exit.
      bloc.add(const SceneEvent.galleryRequested());
      await settle();
      expect(bloc.state, isA<Gallery>());

      bloc.add(const SceneEvent.galleryExited());
      await settle();
      expect(bloc.state, isA<Title>());

      // Each layer has to reach that title in its finished pose without ever
      // having been told to animate there.
      const title = SceneState.title();
      expect(LogoMarkComponent.hasRetreatedBy(title), isTrue);
      expect(BackdropComponent.hasRisenBy(title), isTrue);
      expect(TitleLayerComponent.hasBegunBy(title), isTrue);

      await bloc.close();
    });
  });

  group('the composition the contact screen borrows', () {
    const contact = SceneState.contact();

    test('the mark is the subject again', () {
      expect(contact.showsMark, isTrue);
      expect(const SceneState.logo().showsMark, isTrue);
      expect(const SceneState.loading().showsMark, isTrue);

      expect(const SceneState.title().showsMark, isFalse);
      expect(const SceneState.gallery().showsMark, isFalse);
    });

    test('every layer of the logo screen agrees', () {
      // All three read the same rule, so a fourth stage joining the logo
      // screen's composition cannot arrive at two of them and miss the
      // third — which is what a mark parked in its corner over a contact
      // screen with no subject looks like.
      expect(LogoMarkComponent.hasRetreatedBy(contact), isFalse);
      expect(BackdropComponent.hasRisenBy(contact), isFalse);
      expect(TitleLayerComponent.hasBegunBy(contact), isFalse);
    });
  });
}
