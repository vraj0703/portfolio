import 'package:flutter/material.dart' hide Title;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/data/di/dependency_manager.dart';
import 'package:portfolio/data/di/injection.dart';
import 'package:portfolio/domain/analytics/analytics.dart';
import 'package:portfolio/domain/audio/app_audio.dart';
import 'package:portfolio/domain/radio/radio_player.dart';
import 'package:portfolio/domain/style/strings.dart';
import 'package:portfolio/presentation/bloc/menu_drawer_cubit.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/gallery/gallery_exit_requests.dart';
import 'package:portfolio/presentation/menu/drawer_nav_bar.dart';
import 'package:portfolio/presentation/menu/menu_drawer.dart';
import 'package:portfolio/presentation/menu/title_actions.dart';

import '../../support/scene_harness.dart';
import 'menu_analytics_test.dart' show Sent;

void main() {
  const strings = DefaultAppStrings();

  group('the current destination is the scene\'s to say', () {
    test('title stages are home, the gallery the gallery, contact contact', () {
      expect(const SceneState.title().navCurrent, NavDestination.home);
      expect(const SceneState.active().navCurrent, NavDestination.home);
      expect(const SceneState.gallery().navCurrent, NavDestination.gallery);
      expect(const SceneState.contact().navCurrent, NavDestination.contact);
      expect(const SceneState.loading().navCurrent, isNull);
    });

    test('routes go through today\'s events; from the gallery, its exit', () {
      final home = DrawerNavBar.routeTo(
        NavDestination.home,
        const SceneState.gallery(),
      );
      expect(home.event, const SceneEvent.galleryExited());
      expect(home.viaGalleryExit, isTrue);
      final contact = DrawerNavBar.routeTo(
        NavDestination.contact,
        const SceneState.gallery(),
      );
      expect(contact.event, const SceneEvent.contactRequested());
      expect(contact.viaGalleryExit, isTrue);
      final gallery = DrawerNavBar.routeTo(
        NavDestination.gallery,
        const SceneState.title(),
      );
      expect(gallery.event, const SceneEvent.galleryRequested());
      expect(gallery.viaGalleryExit, isFalse);
    });

    test(
      'the bloc takes the bar\'s gallery and home from the title stages',
      () async {
        final bloc = SceneBloc()..emit(const SceneState.title());
        addTearDown(bloc.close);
        bloc.add(const SceneEvent.galleryRequested());
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state, isA<Gallery>());

        bloc.emit(const SceneState.active());
        bloc.add(const SceneEvent.homeRequested());
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state, isA<Title>());
      },
    );
  });

  group('the bar', () {
    late Sent sent;
    late RecordingRadio radio;
    SceneBloc? scene;
    MenuDrawerCubit? drawer;

    setUp(() async {
      DependencyManager.instance.reset();
      await initDependencies();
      sent = Sent();
      radio = RecordingRadio();
      DependencyManager.instance
        ..registerSingleton<SiteEvents>(
          SiteEvents(sent, viewport: () => (390, 844)),
        )
        ..registerSingleton<RadioPlayer>(radio);
    });

    tearDown(() async {
      await scene?.close();
      await drawer?.close();
      await radio.dispose();
      DependencyManager.instance.reset();
    });

    Future<void> openIn(WidgetTester tester, SceneState state) async {
      final audio = RecordingAudio();
      scene = SceneBloc(audio: audio)..emit(state);
      drawer = MenuDrawerCubit();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: <ThemeExtension<dynamic>>[
              AppAudioExtension(audio: audio),
            ],
          ),
          home: MultiBlocProvider(
            providers: [
              BlocProvider<SceneBloc>.value(value: scene!),
              BlocProvider<MenuDrawerCubit>.value(value: drawer!),
            ],
            child: const Scaffold(
              body: Stack(
                fit: StackFit.expand,
                children: <Widget>[TitleActions(), MenuDrawer()],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(MenuButton));
      await tester.pumpAndSettle();
    }

    Finder dest(NavDestination d) => find.byKey(ValueKey<NavDestination>(d));

    testWidgets('three destinations, 48 dp targets, labelled', (tester) async {
      final handle = tester.ensureSemantics();
      await openIn(tester, const SceneState.title());
      for (final d in NavDestination.values) {
        final size = tester.getSize(dest(d));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
        expect(
          find.bySemanticsLabel(DrawerNavBar.labelFor(d, strings)),
          findsOneWidget,
        );
      }
      handle.dispose();
    });

    testWidgets('tapping the current one only closes the drawer', (
      tester,
    ) async {
      await openIn(tester, const SceneState.title());
      await tester.tap(dest(NavDestination.home));
      await tester.pumpAndSettle();
      expect(drawer!.state, isFalse);
      expect(scene!.state, isA<Title>());
      expect(sent.last('nav_selected'), <String, Object?>{
        ...sent.last('nav_selected'),
        'destination': 'home',
        'already_current': true,
      });
    });

    testWidgets('gallery from the title: there, drawer closed', (tester) async {
      await openIn(tester, const SceneState.title());
      await tester.tap(dest(NavDestination.gallery));
      await tester.pumpAndSettle();
      expect(scene!.state, isA<Gallery>());
      expect(drawer!.state, isFalse);
      expect(sent.last('nav_selected')['destination'], 'gallery');
      expect(sent.last('nav_selected')['already_current'], false);
      expect(sent.last('nav_selected'), contains('from_scene'));
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('contact from the title: the contact page', (tester) async {
      await openIn(tester, const SceneState.title());
      await tester.tap(dest(NavDestination.contact));
      await tester.pumpAndSettle();
      expect(scene!.state, isA<Contact>());
    });

    testWidgets('home from the gallery asks the gallery to leave', (
      tester,
    ) async {
      final asked = <SceneEvent?>[];
      void listen() => asked.add(GalleryExitRequests.instance.take());
      GalleryExitRequests.instance.addListener(listen);
      addTearDown(() => GalleryExitRequests.instance.removeListener(listen));

      await openIn(tester, const SceneState.gallery());
      await tester.tap(dest(NavDestination.home));
      await tester.pumpAndSettle();
      expect(asked, <SceneEvent?>[const SceneEvent.galleryExited()]);
      expect(drawer!.state, isFalse);
      await tester.pump(const Duration(seconds: 5));
    });

    test('nav_selected is in the typed list', () {
      expect(SiteEvents.names, contains('nav_selected'));
    });
  });
}
