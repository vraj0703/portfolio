import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:portfolio/core/di/dependency_manager.dart';
import 'package:portfolio/domain/config/durations.dart';
import 'package:portfolio/domain/models/loading_progress.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/screen/my_game.dart';
import 'package:portfolio/presentation/widgets/curtain_clipper.dart';
import 'package:portfolio/presentation/widgets/loading_screen.dart';

/// The scene: the Flame game, the curtain over it, and the loading screen.
///
/// Stateless. It previously held an [AnimationController] for the curtain and
/// a [MyGame] instance, which is what made it a [StatefulWidget]; neither
/// needs to live here:
///
///  * The curtain's position is a pure function of the scene state — closed
///    while loading, open otherwise — so it is an implicit animation
///    ([TweenAnimationBuilder]) rather than a controller to drive, listen to
///    and dispose.
///  * [GameWidget.controlled] builds the game once and owns it internally, so
///    the instance survives rebuilds without this widget holding it.
///
/// What is drawn is therefore derived entirely from the bloc: no imperative
/// `forward()`/`reverse()` calls, and no listener that has to be kept in sync
/// with the state machine.
class SceneView extends StatelessWidget {
  const SceneView({super.key});

  @override
  Widget build(BuildContext context) {
    final durations = locate<AppDurations>();

    // Read once. The game only pushes events, and the bloc instance is stable
    // for the lifetime of the provider above this widget.
    final queuer = context.read<SceneBloc>();

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // Deliberately outside the BlocBuilder: the game must not be rebuilt
        // on every progress tick.
        GameWidget.controlled(gameFactory: () => MyGame(queuer: queuer)),

        BlocBuilder<SceneBloc, SceneState>(
          builder: (context, state) {
            final isLoading = state is Loading;

            return TweenAnimationBuilder<double>(
              // 0 = curtain closed, 1 = fully open. On the first build the
              // tween has no `begin`, so it settles on 0 without animating —
              // the scene starts covered, which is what we want.
              tween: Tween<double>(end: isLoading ? 0.0 : 1.0),
              duration: durations.reveal,
              curve: Curves.easeInOut,
              builder: (context, reveal, _) {
                return Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    ClipPath(
                      clipper: CurtainClipper(revealProgress: reveal),
                      child: const ColoredBox(color: Colors.black),
                    ),

                    // Leaves *with* the curtain rather than popping out a
                    // frame before it starts: the reveal drives the mark's
                    // swell-and-flash exit. Once fully revealed it is gone
                    // entirely, costing nothing.
                    if (reveal < 1)
                      LoadingScreen(
                        exit: reveal,
                        // After leaving `loading` the bar has, by definition,
                        // finished — so it reads 100% on the way out rather
                        // than snapping back to zero.
                        progress: isLoading
                            ? state.progress
                            : LoadingProgress.complete,
                      ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}
