import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:portfolio/data/di/dependency_manager.dart';
import 'package:portfolio/presentation/bloc/menu_drawer_cubit.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/bloc/sound_cubit.dart';
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
          create: (_) =>
              locate<SceneBloc>()..add(const SceneEvent.initialize()),
        ),

        // Beside the scene's state, not inside it. Whether a panel is open
        // is not a fact about where the visitor is, and folding it in would
        // make every scene transition decide what happens to the drawer.
        BlocProvider(create: (_) => locate<MenuDrawerCubit>()),

        // Whether the site is silent, so the switch that flips it can stay
        // stateless.
        BlocProvider(create: (_) => locate<SoundCubit>()),
      ],
      // The gallery starts building once the title has finished arriving —
      // not before, so it never competes with the title for a frame.
      child: const GalleryPreload(child: Scaffold(body: SceneView())),
    );
  }
}

/// Starts the gallery's build once the title sequence has arrived.
///
/// The build used to start on the first frame and the loading screen waited
/// for it: minutes on a throttled phone, for a room the visitor reaches long
/// after the title. Now it waits for the title's entrance to be *reported*
/// complete — the move to [Active] — and runs in idle-priority steps from
/// there, so it never takes a frame of the name and the sun. A visitor who
/// scrolls on before it is done meets the crossing's own short progress.
///
/// Any later stage starts it too, should one be reached first.
class GalleryPreload extends StatelessWidget {
  const GalleryPreload({required this.child, super.key});

  final Widget child;

  static bool _started = false;

  static bool shouldStart(SceneState state) =>
      state is Active || state is Gallery || state is Contact;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SceneBloc, SceneState>(
      listenWhen: (previous, current) => !_started && shouldStart(current),
      listener: (context, state) => _start(),
      child: child,
    );
  }

  static void _start() {
    if (_started) return;
    _started = true;
    // Guarded, not merely awaited: bringing up the scene starts GPU work of
    // its own, and a failure surfaces from inside the engine's async work
    // where a catchError never sees it. Background work the visitor never
    // asked for must not take the app down; the view reports a failure if
    // they arrive.
    runZonedGuarded(() => GalleryScene.warmUp(background: true), (
      error,
      stack,
    ) {
      debugPrint('[gallery] background build failed: $error');
      debugPrint('$stack');
    });
  }
}
