import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:portfolio/core/di/dependency_manager.dart';
import 'package:portfolio/domain/config/durations.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/screen/my_game.dart';
import 'package:portfolio/presentation/widgets/curtain_clipper.dart';

class StatefulScene extends StatefulWidget {
  final VoidCallback onClick;

  const StatefulScene({super.key, required this.onClick});

  @override
  State<StatefulScene> createState() => _StatefulSceneState();
}

class _StatefulSceneState extends State<StatefulScene>
    with TickerProviderStateMixin {
  late final AnimationController _revealController;
  late SceneBloc _bloc;
  late final MyGame _game;

  @override
  void initState() {
    super.initState();
    final durations = locate<AppDurations>();
    _bloc = BlocProvider.of<SceneBloc>(context);

    // This controller drives the curtain opening and the in-game animations.
    _revealController = AnimationController(
      vsync: this,
      duration: durations.reveal,
    );

    // Link the controller to our global notifier.
    _revealController.addListener(_updateSceneProgress);

    _revealController.addStatusListener((status) {
      // When the curtain has fully closed (animation is 'dismissed')
      if (status == AnimationStatus.dismissed) {
        widget.onClick(); // Call the final callback
      }
    });

    _game = MyGame(bloc: _bloc);
  }

  void _updateSceneProgress() {}

  @override
  void dispose() {
    _revealController.removeListener(_updateSceneProgress);
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SceneBloc, SceneState>(
      listenWhen: (previous, current) {
        return previous.runtimeType != current.runtimeType;
      },
      listener: (context, state) {
        state.when(
          loading: (isSvgReady, isGameReady) {
            _revealController.reverse();
          },
          logo: () {
            if (mounted) {
              _revealController.forward();
            }
          },
          logoOverlayRemoving: () {},
          titleLoading: () {},
          title: () {},
          active: (_, _) {},
        );
      },
      builder: (context, state) {
        return Listener(
          onPointerHover: (event) {},
          child: MouseRegion(
            onEnter: (event) {},
            onHover: (event) {},
            child: Stack(
              alignment: Alignment.center,
              children: [
                GameWidget(game: _game),

                // Layer 2: The Black Curtain.
                // This is the core of the curtain effect. It's a black container that
                // is "clipped" away by an animated path.
                AnimatedBuilder(
                  animation: _revealController,
                  builder: (context, child) {
                    return ClipPath(
                      // The custom clipper uses the controller's value to animate the path.
                      clipper: CurtainClipper(
                        revealProgress: _revealController.value,
                      ),
                      child: Container(color: Colors.black),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
