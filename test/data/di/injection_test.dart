import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/data/config/durations.dart';
import 'package:portfolio/data/di/dependency_manager.dart';
import 'package:portfolio/data/di/injection.dart';
import 'package:portfolio/domain/config/durations.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';

void main() {
  setUp(() async {
    // The container is a process-wide singleton and registration throws on a
    // duplicate, so each case starts from empty.
    DependencyManager.instance.reset();
    await initDependencies();
  });

  tearDown(() => DependencyManager.instance.reset());

  group('initDependencies', () {
    test('resolves AppDurations', () {
      expect(locate<AppDurations>(), isA<AppDurationsImpl>());
    });

    test('shares one AppDurations instance', () {
      expect(identical(locate<AppDurations>(), locate<AppDurations>()), isTrue);
    });

    test('resolves SceneBloc', () {
      final bloc = locate<SceneBloc>();
      addTearDown(bloc.close);
      expect(bloc, isA<SceneBloc>());
    });

    test('hands out a fresh SceneBloc every time', () {
      // Load-bearing. BlocProvider closes whatever it creates, so a shared
      // instance would come back closed on a second mount and the next event
      // would throw. If this ever passes as `isTrue`, the registration has
      // been changed to a singleton and the scene will break on remount.
      final first = locate<SceneBloc>();
      final second = locate<SceneBloc>();
      addTearDown(first.close);
      addTearDown(second.close);

      expect(identical(first, second), isFalse);
    });

    test('a closed SceneBloc does not poison the next resolution', () async {
      final first = locate<SceneBloc>();
      await first.close();

      final second = locate<SceneBloc>();
      addTearDown(second.close);

      // The replacement must be usable — this is the remount path.
      expect(second.isClosed, isFalse);
      second.add(const SceneEvent.initialize());
    });
  });

  group('DependencyManager', () {
    test('throws for a type that was never registered', () {
      DependencyManager.instance.reset();
      expect(() => locate<AppDurations>(), throwsException);
    });

    test('throws when the same type is registered twice', () {
      expect(
        () => DependencyManager.instance.registerFactory<SceneBloc>(
          SceneBloc.new,
        ),
        throwsException,
      );
    });

    test('reset clears every registration', () {
      DependencyManager.instance.reset();
      expect(() => locate<SceneBloc>(), throwsException);
      expect(() => locate<AppDurations>(), throwsException);
    });
  });
}
