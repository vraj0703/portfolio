import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:portfolio/domain/gallery/gallery_camera_path.dart';
import 'package:portfolio/domain/gallery/gallery_shape.dart';
import 'package:portfolio/data/di/dependency_manager.dart';
import 'package:portfolio/domain/models/loading_phase.dart';
import 'package:portfolio/presentation/bloc/menu_drawer_cubit.dart';
import 'package:portfolio/domain/analytics/analytics.dart';
import 'package:portfolio/domain/config/button_flags.dart';
import 'package:portfolio/presentation/analytics/site_telemetry.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/gallery/gallery_scene_builder.dart';
import 'package:portfolio/presentation/screen/scene_view.dart';

/// Provides the scene's state machine and hosts the scene itself.
class FlameScene extends StatelessWidget {
  const FlameScene({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          // Resolved through the container rather than constructed here, so
          // the bloc's dependencies can grow without this widget knowing.
          // Registered as a factory, so each provider gets an instance it
          // exclusively owns and closes.
          create: (_) {
            final bloc = locate<SceneBloc>()
              ..add(const SceneEvent.initialize());
            _warmGallery(bloc);
            _report(bloc);
            return bloc;
          },
        ),

        // Beside the scene's state, not inside it. Whether a panel is open
        // is not a fact about where the visitor is, and folding it in would
        // make every scene transition decide what happens to the drawer.
        BlocProvider(create: (_) => locate<MenuDrawerCubit>()),
      ],
      child: const Scaffold(body: SceneView()),
    );
  }

  /// The analytics' one listener on the scene, and the flags' way in.
  ///
  /// Scenes are read from the bloc's states, not reported by each widget;
  /// the title's button flags arrive as an event, so the widgets read them
  /// from the state like every other rule (see [SceneState.showsConnect]).
  static void _report(SceneBloc bloc) {
    final telemetry = locate<SiteTelemetry>();
    final events = locate<SiteEvents>();
    telemetry.onScene(bloc.state);
    bloc.stream.listen(telemetry.onScene);
    events.flagsChanged.addListener(() {
      if (bloc.isClosed) return;
      bloc.add(
        SceneEvent.flagsChanged(
          flags: ButtonFlags(
            connect: events.showsConnect(),
            menu: events.showsMenu(),
            walkStick: events.walksByStick(),
          ),
        ),
      );
    });
  }

  /// Starts building the gallery while the loading screen is still up.
  ///
  /// The gallery is the heaviest thing the site builds, and it is the last
  /// thing the visitor reaches — several minutes of intro later. Loading it on
  /// arrival means a wait with nothing on screen; loading it here means the
  /// wait happens once, behind the bar that exists to cover exactly this.
  ///
  /// Deferred to after the first frame because building the scene needs a GPU
  /// context, which does not exist until the engine has painted once.
  /// The window's width over height, read off the engine: the warm-up runs
  /// outside any widget's build. A laptop's when there is no view yet.
  static double _screenAspect() {
    final size =
        WidgetsBinding.instance.platformDispatcher.implicitView?.physicalSize;
    if (size == null || size.isEmpty) return GalleryCameraPath.landscape;
    return size.width / size.height;
  }

  static void _warmGallery(SceneBloc bloc) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Guarded, not merely awaited. The scene brings up a GPU context, and
      // when that is unavailable — a headless test, a device without the
      // backend — the failure surfaces from inside the engine's own async
      // work rather than on the future returned here. A `catchError` never
      // sees it, so the zone is what catches it.
      //
      // This is background work the visitor never asked for; it must not be
      // able to take the app down.
      runZonedGuarded(
        () {
          GalleryScene.warmUp(
            // The corridor's shape for this screen, chosen once with the
            // build (see [GalleryShape]).
            shape: GalleryShape.forAspect(_screenAspect()),
            onProgress: (value) => bloc.add(
              SceneEvent.loadingProgressed(
                phase: LoadingPhase.gallery,
                value: value,
              ),
            ),
          );
        },
        (error, stack) {
          // Logged in every build, not just debug. A failure here is silent
          // by design — the intro carries on and the loading bar completes —
          // so without this the only symptom is the bar jumping to the end,
          // which is indistinguishable from it having simply finished.
          debugPrint('[gallery] warm-up failed: $error');
          debugPrint('$stack');
          _releaseGalleryPhase(bloc);
        },
      );
    });
  }

  /// Lets the loading screen finish without the gallery.
  ///
  /// A gallery that will not build must not strand the visitor behind the bar
  /// forever. The intro runs; the view surfaces the failure if they arrive.
  static void _releaseGalleryPhase(SceneBloc bloc) {
    if (bloc.isClosed) return;
    bloc.add(
      const SceneEvent.loadingProgressed(phase: LoadingPhase.gallery, value: 1),
    );

    // And the warm-up with it. It draws the built scene, so a scene that was
    // never built leaves it with nothing to draw and nothing to report — and
    // a phase nobody reports against holds the curtain down forever.
    bloc.add(
      const SceneEvent.loadingProgressed(phase: LoadingPhase.priming, value: 1),
    );
  }
}
