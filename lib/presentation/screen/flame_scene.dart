import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projects/presentation/bloc/scene_bloc.dart';
import 'package:projects/presentation/screen/stateful_scene.dart';

class FlameScene extends StatelessWidget {
  final VoidCallback onClick;

  const FlameScene({super.key, required this.onClick});

  @override
  Widget build(BuildContext context) {
    // Initialize feature flags with the website's defaults if no consumer
    // (e.g., base_app) has already done so. Calling init() repeatedly with
    // the same map is idempotent — last writer wins, but our default is
    // identical to base_app's so re-initialization is safe.
    // FeatureFlags().init(MenuFeatures.defaultFlags);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) {
            final bloc = SceneBloc();
            bloc.add(SceneEvent.initialize());
            return bloc;
          },
        ),
      ],
      child: Scaffold(body: StatefulScene(onClick: onClick)),
    );
  }
}
