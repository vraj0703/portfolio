import 'package:portfolio/core/di/dependency_manager.dart';
import 'package:portfolio/data/config/durations.dart';
import 'package:portfolio/domain/config/durations.dart';
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
  di.registerFactory<SceneBloc>(() => SceneBloc());
}
