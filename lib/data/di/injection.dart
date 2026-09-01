import 'package:portfolio/data/audio/flame_app_audio.dart';
import 'package:portfolio/data/config/durations.dart';
import 'package:portfolio/data/contact/url_contact_links.dart';
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

  di.registerFactory<SceneBloc>(() => SceneBloc(radio: di.get<RadioPlayer>()));

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
  di.registerLazySingleton<ContactLinks>(
    () => UrlContactLinks(profile: ContactProfile.vishal),
  );
}
