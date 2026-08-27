import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:portfolio/core/di/dependency_manager.dart';
import 'package:portfolio/domain/models/loading_phase.dart';
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
            return bloc;
          },
        ),
      ],
      child: const Scaffold(body: SceneView()),
    );
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
            onProgress: (value) => bloc.add(
              SceneEvent.loadingProgressed(
                phase: LoadingPhase.gallery,
                value: value,
              ),
            ),
          );
        },
        (error, stack) {
          if (kDebugMode) debugPrint('[gallery] warm-up failed: $error');
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
      const SceneEvent.loadingProgressed(
        phase: LoadingPhase.gallery,
        value: 1,
      ),
    );
  }
}
