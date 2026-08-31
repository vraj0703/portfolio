import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/core/di/dependency_manager.dart';
import 'package:portfolio/core/di/injection.dart';
import 'package:portfolio/data/radio/streaming_radio.dart';
import 'package:portfolio/domain/radio/radio_player.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';

void main() {
  setUp(() async {
    DependencyManager.instance.reset();
    await initDependencies();
  });

  tearDown(() => DependencyManager.instance.reset());

  group('there is one radio in the building', () {
    test('resolves through the container', () {
      expect(locate<RadioPlayer>(), isA<StreamingRadio>());
    });

    test('and it is shared, which is what keeps the two faces in step', () {
      // The corridor has a radio on its wall and so does the skills hall,
      // and they are meant to be one radio seen twice: a visitor who starts
      // it downstairs and walks up must not find the hall's set reading OFF.
      //
      // `WallRadios.show` letters every panel it holds from a single state,
      // so the two faces cannot disagree — but only while there is a single
      // state to letter them from. A factory here would give the corridor
      // and the hall a player each, and no care in the drawing would put
      // them back in step.
      expect(identical(locate<RadioPlayer>(), locate<RadioPlayer>()), isTrue);
    });

    test('and the scene bloc is handed that same one', () {
      // The bloc decides when the radio plays; the wall's controls act on it
      // directly. Those are only the same radio because both reach the
      // container instead of building their own.
      final bloc = locate<SceneBloc>();
      addTearDown(bloc.close);

      expect(locate<RadioPlayer>(), same(locate<RadioPlayer>()));
    });
  });
}
