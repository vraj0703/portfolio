import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/audio/app_audio.dart';
import 'package:portfolio/domain/config/scene_layers.dart';
import 'package:portfolio/domain/models/loading_phase.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/domain/style/scene_palette.dart';
import 'package:portfolio/domain/style/strings.dart';
import 'package:portfolio/domain/style/text_styles.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/game/backdrop_component.dart';
import 'package:portfolio/presentation/game/bold_text_component.dart';
import 'package:portfolio/presentation/game/logo_layer.dart';
import 'package:portfolio/presentation/game/logo_overlay_component.dart';
import 'package:portfolio/presentation/game/scroll_cue_component.dart';
import 'package:portfolio/presentation/game/title_layer_component.dart';
import 'package:portfolio/presentation/screen/my_game.dart';

ScenePalette _palette() {
  const colors = DefaultAppColors();
  const strings = DefaultAppStrings();
  const type = DefaultAppTypography();

  return ScenePalette(
    background: colors.sceneBackground,
    overlayText: colors.logoOverlayText,
    overlayTextShadow: colors.logoOverlayTextShadow,
    lineGradient: colors.logoLineGradient,
    lineStops: colors.logoLineStops,
    enterStyle: type.enter,
    tapToEnter: strings.tapToEnter,
    primaryTitle: strings.primaryTitle,
    secondaryTitle: strings.secondaryTitle,
    titlePrimaryStyle: type.titlePrimary,
    titleSecondaryStyle: type.titleSecondary,
    titleBase: colors.titleBase,
    scrollCue: colors.scrollCue,
    boldText: strings.boldText,
    boldTextStyle: type.boldText,
  );
}

late SceneBloc bloc;

MyGame _buildGame() {
  bloc = SceneBloc();
  return MyGame(
    bloc: bloc,
    palette: _palette(),
    audio: const SilentAudio(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async => bloc.close());

  group('MyGame', () {
    testWithGame<MyGame>('mounts every layer of the scene', _buildGame, (game) async {
        // Regression guard for a whole class of mistake: a component that is
        // constructed, configured and referenced, but never added to the
        // tree. Nothing throws — it simply never renders and never receives
        // a state change, which looks like a styling or ordering bug rather
        // than a missing widget.
        //
        // The scroll cue shipped exactly that way: its audio cue fired (that
        // comes from the game's own bloc listener) while the arrow itself was
        // never on screen.
        await game.ready();
        final mounted = game.descendants().toList();

        expect(mounted.whereType<LogoShadowComponent>(), hasLength(1));
        expect(mounted.whereType<BackdropComponent>(), hasLength(1));
        expect(mounted.whereType<LogoMarkComponent>(), hasLength(1));
        expect(mounted.whereType<LogoOverlayComponent>(), hasLength(1));
        expect(mounted.whereType<TitleLayerComponent>(), hasLength(1));
        expect(mounted.whereType<BoldTextComponent>(), hasLength(1));
        expect(mounted.whereType<ScrollCueComponent>(), hasLength(1));
    });

    testWithGame<MyGame>('stacks the layers in the documented order', _buildGame, (game) async {
        await game.ready();
        final mounted = game.descendants().toList();

        int priorityOf<T extends Component>() =>
            mounted.whereType<T>().single.priority;

        expect(priorityOf<LogoShadowComponent>(), SceneLayers.shadow);
        expect(priorityOf<BackdropComponent>(), SceneLayers.backdrop);
        expect(priorityOf<LogoMarkComponent>(), SceneLayers.mark);
        expect(priorityOf<LogoOverlayComponent>(), SceneLayers.affordance);
        expect(priorityOf<TitleLayerComponent>(), SceneLayers.title);
        expect(priorityOf<BoldTextComponent>(), SceneLayers.boldText);
        expect(priorityOf<ScrollCueComponent>(), SceneLayers.scrollCue);
    });

    testWithGame<MyGame>('reports its loading phase as complete', _buildGame, (
      game,
    ) async {
      // A game that loads without reporting hangs the whole app behind the
      // loading screen. Asserted on its own phase rather than on the scene
      // leaving loading: the gallery loads alongside it now, and the scene
      // waits for both.
      await Future<void>.delayed(Duration.zero);

      final state = game.bloc.state;
      expect(state, isA<Loading>(), reason: 'gallery has not reported here');
      expect((state as Loading).progress.of(LoadingPhase.game), 1);
    });

    testWithGame<MyGame>('paints the scene on the theme ground', _buildGame, (game) async {
      expect(game.backgroundColor(), _palette().background);
    });
  });
}
