import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';

import '../../support/scene_journey.dart';

void main() {
  test('the sign on the left wall returns the visitor to the title', () async {
    final bloc = await inTheGallery();
    expect(bloc.state, isA<Gallery>(), reason: 'precondition');

    bloc.add(const SceneEvent.galleryExited());
    await settle();

    // `title`, not `titleLoading`. The game is no longer torn down on the way
    // into the corridor, so the stage is still standing exactly as it was
    // left; replaying its entrance would animate something already on screen.
    //
    // And not the bold-text stage they scrolled through to get here: that is
    // a one-way passage on a scroll already spent, and landing back inside it
    // strands them mid-animation.
    expect(bloc.state, isA<Title>());

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
