import 'package:portfolio/domain/models/loading_phase.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';

/// Lets the bloc deliver what it has been handed.
///
/// `emit` is asynchronous, so a state read straight after an `add` is the
/// state before it.
Future<void> settle() => Future<void>.delayed(Duration.zero);

/// Drives the scene all the way to the gallery, the way a visitor does.
///
/// Shared, because two suites had byte-identical copies of it. A walk-through
/// like this is the one helper that must not be duplicated: it encodes the
/// order the whole state machine runs in, so a copy that falls behind does
/// not fail — it goes on testing a sequence the app no longer has.
Future<SceneBloc> inTheGallery() async {
  final bloc = SceneBloc()..add(const SceneEvent.initialize());
  for (final phase in LoadingPhase.values) {
    bloc.add(SceneEvent.loadingProgressed(phase: phase, value: 1));
  }
  bloc.add(const SceneEvent.logoEntranceCompleted());
  await settle();

  bloc.add(const SceneEvent.tapped());
  await settle();
  bloc.add(const SceneEvent.logoExitCompleted());
  await settle();
  bloc.add(const SceneEvent.titleEntranceCompleted());
  await settle();
  bloc.add(const SceneEvent.advanceRequested());
  await settle();
  bloc.add(const SceneEvent.boldTextCompleted());
  await settle();

  return bloc;
}

/// Carries on from [inTheGallery] to the contact screen.
Future<SceneBloc> onTheContactScreen() async {
  final bloc = await inTheGallery();
  bloc.add(const SceneEvent.contactRequested());
  await settle();
  return bloc;
}
