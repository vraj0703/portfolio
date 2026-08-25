import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:portfolio/core/di/dependency_manager.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
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
          create: (_) => locate<SceneBloc>()..add(const SceneEvent.initialize()),
        ),
      ],
      child: const Scaffold(body: SceneView()),
    );
  }
}
