import 'dart:ui' show PlatformDispatcher;

import 'package:portfolio/data/analytics/analytics_setup.dart';
import 'package:portfolio/data/audio/flame_app_audio.dart';
import 'package:portfolio/domain/analytics/analytics.dart';
import 'package:portfolio/domain/config/button_flags.dart';
import 'package:portfolio/presentation/analytics/site_telemetry.dart';
import 'package:portfolio/data/config/durations.dart';
import 'package:portfolio/data/contact/url_contact_links.dart';
import 'package:portfolio/data/recommendations/local_recommendation_store.dart';
import 'package:portfolio/domain/gallery/testimonial_data.dart';
import 'package:portfolio/data/di/dependency_manager.dart';
import 'package:portfolio/data/radio/streaming_radio.dart';
import 'package:portfolio/domain/audio/app_audio.dart';
import 'package:portfolio/domain/config/durations.dart';
import 'package:portfolio/domain/contact/contact_links.dart';
import 'package:portfolio/domain/radio/radio_player.dart';
import 'package:portfolio/presentation/bloc/menu_drawer_cubit.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';

Future<void> initDependencies() async {
  final di = DependencyManager.instance;

  // Config — stateless and shared, so a lazy singleton is enough.
  di.registerLazySingleton<AppDurations>(() => AppDurationsImpl());

  // SceneBloc is a *factory*, deliberately.
  //
  // BlocProvider takes ownership of whatever its `create` returns and closes
  // it when the provider is disposed. A singleton would therefore come back
  // already-closed the second time the scene mounts, and the next event would
  // throw "Cannot add new events after calling close". A factory hands each
  // provider its own instance to own and close.
  // Handed the radio, because the bloc decides when it plays: the wall it
  // hangs on is the gallery's, but *which screen the visitor is on* is the
  // scene's to know, and that is the whole of the question.
  // A drawer per screen that shows one, not one for the app: it is opened
  // and closed by a single widget subtree and has nothing to say to anything
  // outside it.
  di.registerFactory<MenuDrawerCubit>(MenuDrawerCubit.new);

  // A factory for the same reason, and seeded from the shared audio backend
  // so a remounted scene shows the mute the visit already chose.
  // Analytics: PostHog with a token, silence without one. A build with no
  // token sends nothing and loads nothing (docs/analytics/README.md).
  di.registerLazySingleton<Analytics>(createAnalytics);
  di.registerLazySingleton<SiteEvents>(
    () => SiteEvents(
      di.get<Analytics>(),
      viewport: () {
        final view = PlatformDispatcher.instance.implicitView;
        if (view == null) return (0, 0);
        final size = view.physicalSize / view.devicePixelRatio;
        return (size.width, size.height);
      },
    ),
  );
  di.registerLazySingleton<SiteTelemetry>(
    () => SiteTelemetry(di.get<SiteEvents>()),
  );

  di.registerFactory<SceneBloc>(() {
    final events = di.get<SiteEvents>();
    return SceneBloc(
      radio: di.get<RadioPlayer>(),
      audio: di.get<AppAudio>(),
      events: events,
      // The compiled defaults, or what the flags already say: never waits.
      flags: ButtonFlags(
        connect: events.showsConnect(),
        menu: events.showsMenu(),
      ),
    );
  });

  // One shared audio backend: it owns a cache and a pool of players, so a
  // second instance would duplicate both and let cues talk over each other.
  di.registerLazySingleton<AppAudio>(FlameAppAudio.new);

  // One radio for the whole visit, and a lazy one: it holds an open
  // connection to somebody else's server while it plays, so a second
  // instance would be a second stream nobody is listening to — and lazy
  // because nothing should dial out before a visitor asks it to.
  di.registerLazySingleton<RadioPlayer>(StreamingRadio.new);

  // Everything the contact menu reaches for outside the scene. Stateless, and
  // behind an interface so the menu can be exercised without a platform
  // channel underneath it.
  // A visitor's own pending recommendation, in their browser only.
  di.registerLazySingleton<RecommendationStore>(LocalRecommendationStore.new);

  di.registerLazySingleton<ContactLinks>(
    () => UrlContactLinks(profile: ContactProfile.vishal),
  );
}
