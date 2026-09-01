import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:portfolio/data/di/dependency_manager.dart';
import 'package:portfolio/domain/audio/app_audio.dart';
import 'package:portfolio/domain/config/durations.dart';
import 'package:portfolio/domain/models/loading_progress.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/domain/style/scene_palette.dart';
import 'package:portfolio/presentation/gallery/gallery_primer.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/menu/menu_button.dart';
import 'package:portfolio/presentation/menu/menu_drawer.dart';
import 'package:portfolio/presentation/gallery/gallery_view.dart';
import 'package:portfolio/presentation/gallery/gallery_warm_render.dart';
import 'package:portfolio/presentation/screen/contact_menu_layer.dart';
import 'package:portfolio/presentation/screen/my_game.dart';
import 'package:portfolio/presentation/screen/scene_input.dart';
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

    // Read once. The bloc instance is stable for the lifetime of the provider
    // above this widget, and the palette is resolved here because Flame
    // components have no BuildContext of their own.
    final bloc = context.read<SceneBloc>();
    final palette = ScenePalette.of(context);
    final audio = context.audio;

    return SceneInput(
      bloc: bloc,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // The gallery is a separate renderer, so it replaces the Flame scene
          // rather than layering over it. Mounted only in its own state: it
          // holds GPU resources, and keeping it alive through the intro would
          // pay for a corridor nobody is looking at.
          BlocBuilder<SceneBloc, SceneState>(
            buildWhen: (previous, current) =>
                (previous is Gallery) != (current is Gallery),
            builder: (context, state) => state is Gallery
                ? const GalleryView()
                : const SizedBox.shrink(),
          ),

          // Bottom of the stack, and painted over by everything above it. This
          // is the gallery being drawn once, small, while the intro is still
          // running, so the frame the visitor actually arrives on is not the
          // one paying to compile its shaders. Rebuilt with the rest of the
          // tree, so it appears on the first state change after the scene
          // finishes building and stops mattering once the real view mounts.
          // Positioned, because a non-positioned child of an expanding Stack is
          // given tight constraints — the warm render's own size would be
          // discarded and it would draw at full screen, which is the expense it
          // exists to avoid.
          Positioned(
            top: 0,
            left: 0,
            width: GalleryWarmRender.edge,
            height: GalleryWarmRender.edge,
            child: BlocBuilder<SceneBloc, SceneState>(
              builder: (context, state) => state is Gallery
                  ? const SizedBox.shrink()
                  : const GalleryWarmRender(),
            ),
          ),

          // Deliberately outside the BlocBuilder: the game must not be rebuilt
          // on every progress tick.
          BlocBuilder<SceneBloc, SceneState>(
            buildWhen: (previous, current) =>
                (previous is Gallery) != (current is Gallery),
            // Hidden, not unmounted. Tearing the game down on the way into
            // the corridor threw the whole intro away: every component keys
            // its behaviour off transitions, so a game rebuilt on the way
            // back mounted into a stage it had never seen arrive and simply
            // sat there — the title never started, the mark never retreated.
            // Off stage it lays out but does not paint, so the corridor still
            // has the screen to itself, and coming back is a return rather
            // than a reconstruction.
            builder: (context, state) => Offstage(
              offstage: state is Gallery,
              child: GameWidget.controlled(
                gameFactory: () =>
                    MyGame(bloc: bloc, palette: palette, audio: audio),
              ),
            ),
          ),

          // Over the game and under the curtain. The composition beneath is
          // the logo screen's, drawn by the same components that drew it the
          // first time; this is only what stands where "TAP TO ENTER" stood.
          const ContactMenuLayer(),

          // The title screen's way out, and the panel it opens. Above the
          // scene and below the curtain, so loading covers them like
          // everything else.
          const MenuButton(),
          const MenuDrawer(),

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
                      // Under the curtain, and only while it is down. This
                      // draws the finished corridor where nobody can see it,
                      // so the pipelines its materials need are compiled
                      // during a wait the visitor has already been asked for
                      // rather than on the first frame after it.
                      //
                      // Below the `ClipPath`, never above: it has to be
                      // painted to be warmed, and it must not be seen.
                      if (isLoading) GalleryPrimer(queuer: context.read<SceneBloc>()),

                      ClipPath(
                        clipper: CurtainClipper(revealProgress: reveal),
                        child: ColoredBox(color: context.colors.curtain),
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
      ),
    );
  }
}
