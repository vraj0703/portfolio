import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/gallery/gallery_view.dart';

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('the one way out of the gallery', () {
    test('request -> leaving -> arrived, for the title', () async {
      final bloc = SceneBloc()..emit(const SceneState.gallery());
      addTearDown(bloc.close);

      bloc.add(const SceneEvent.galleryExitRequested(to: GalleryExit.title));
      await settle();
      expect(bloc.state, isA<Gallery>());
      expect(bloc.state.galleryLeavingFor, GalleryExit.title);

      // The gallery's fade ends and raises the arrival event.
      bloc.add(GalleryLeaving.arrivalFor(GalleryExit.title));
      await settle();
      expect(bloc.state, isA<Title>());
    });

    test('and for the contact page', () async {
      final bloc = SceneBloc()..emit(const SceneState.gallery());
      addTearDown(bloc.close);

      bloc.add(const SceneEvent.galleryExitRequested(to: GalleryExit.contact));
      await settle();
      expect(bloc.state.galleryLeavingFor, GalleryExit.contact);

      bloc.add(GalleryLeaving.arrivalFor(GalleryExit.contact));
      await settle();
      expect(bloc.state, isA<Contact>());
    });

    test('a second request while leaving is ignored', () async {
      final bloc = SceneBloc()..emit(const SceneState.gallery());
      addTearDown(bloc.close);

      bloc
        ..add(const SceneEvent.galleryExitRequested(to: GalleryExit.title))
        ..add(const SceneEvent.galleryExitRequested(to: GalleryExit.contact));
      await settle();
      expect(bloc.state.galleryLeavingFor, GalleryExit.title);
    });

    test('a request outside the gallery is ignored', () async {
      final bloc = SceneBloc()..emit(const SceneState.title());
      addTearDown(bloc.close);

      bloc.add(const SceneEvent.galleryExitRequested(to: GalleryExit.title));
      await settle();
      expect(bloc.state, isA<Title>());
      expect(bloc.state.galleryLeavingFor, isNull);
    });

    test('leaving survives the flags and the sound switch', () async {
      final bloc = SceneBloc()..emit(const SceneState.gallery());
      addTearDown(bloc.close);

      bloc.add(const SceneEvent.galleryExitRequested(to: GalleryExit.title));
      await settle();
      bloc.add(const SceneEvent.muteToggled());
      await settle();
      expect(bloc.state.galleryLeavingFor, GalleryExit.title);
    });
  });

  group('the fade runs from the state', () {
    test('its length and its arrival depend only on where to', () {
      expect(
        GalleryLeaving.durationFor(GalleryExit.title),
        GalleryView.leaving,
      );
      expect(
        GalleryLeaving.durationFor(GalleryExit.contact),
        GalleryView.leavingWithMark,
      );
      expect(
        GalleryLeaving.arrivalFor(GalleryExit.title),
        const SceneEvent.galleryExited(),
      );
      expect(
        GalleryLeaving.arrivalFor(GalleryExit.contact),
        const SceneEvent.contactRequested(),
      );
    });
  });
}
