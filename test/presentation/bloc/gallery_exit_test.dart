import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/models/loading_phase.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';

Future<void> settle() => Future<void>.delayed(Duration.zero);

/// Drives the scene all the way to the gallery, the way a visitor does.
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

void main() {
  test('the sign on the left wall returns the visitor to the title', () async {
    final bloc = await inTheGallery();
    expect(bloc.state, isA<Gallery>(), reason: 'precondition');

    bloc.add(const SceneEvent.galleryExited());
    await settle();

    // `titleLoading`, not `title`. The stage's components drive themselves
    // from the entrance, so handing them the finished state leaves the title
    // never having been told to appear and the visitor lands on a bare logo.
    // And not the bold-text stage they scrolled through to get here: that is
    // a one-way passage on a scroll already spent, and landing back inside
    // it strands them mid-animation.
    expect(bloc.state, isA<TitleLoading>());

    await bloc.close();
  });

  test('leaving is only offered from inside the gallery', () async {
    final bloc = SceneBloc()..add(const SceneEvent.initialize());
    await settle();
    final before = bloc.state;

    bloc.add(const SceneEvent.galleryExited());
    await settle();

    expect(bloc.state, before);
    await bloc.close();
  });
}
