import 'package:projects/core/di/dependency_manager.dart';
import 'package:projects/data/config/durations.dart';
import 'package:projects/domain/config/durations.dart';

Future<void> initDependencies() async {
  final di = DependencyManager.instance;

  // Register your dependencies here
  di.registerLazySingleton<AppDurations>(() => AppDurationsImpl());
}
