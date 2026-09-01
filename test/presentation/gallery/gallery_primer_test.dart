import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/gallery_camera_path.dart';
import 'package:portfolio/domain/gallery/gallery_dimensions.dart';
import 'package:portfolio/domain/interfaces/queuer.dart';
import 'package:portfolio/domain/models/loading_phase.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/gallery/gallery_primer.dart';
import 'package:portfolio/presentation/gallery/scene_axes.dart';

class _Recorder implements Queuer {
  final List<SceneEvent> events = <SceneEvent>[];

  @override
  void queue({required SceneEvent event}) => events.add(event);
}

void main() {
  group('the warm-up draws what the visitor will actually see', () {
    test('through the entry pose, not from wherever the camera starts', () {
      // The failure this guards against has happened once already, in the
      // form it removed from `GalleryView`: a warm-up frame that draws the
      // wrong thing compiles the wrong pipelines and warms nothing. Anything
      // outside this camera's frustum is culled and never submitted.
      final pose = GalleryCameraPath.poseAt(0);
      final camera = GalleryPrimer.entryCamera;

      expect(camera.position, SceneAxes.position(pose.position));
      expect(camera.target, SceneAxes.position(pose.target));
    });

    test('and through the lens the room itself uses', () {
      // A different field of view is a different frustum, which is a
      // different set of nodes submitted — so the wrong pipelines again,
      // from a camera standing in exactly the right place.
      expect(
        GalleryPrimer.entryCamera.fovRadiansY,
        GalleryDimensions.fovRadians,
      );
    });

    test('at a fraction of the pixels, because size is not what is warmed', () {
      // Which pipelines compile depends on the materials submitted, and
      // culling depends on the frustum. Neither depends on raster size, so
      // this can be cheap — but not zero, because a frame that rasterises
      // nothing does not compile anything either.
      expect(GalleryPrimer.pixelRatio, greaterThan(0));
      expect(GalleryPrimer.pixelRatio, lessThan(0.5));
    });
  });

  group('the curtain waits for it', () {
    testWidgets('and it draws nothing before there is a scene to draw', (
      tester,
    ) async {
      // `GalleryScene.ready` is null until the gallery has finished building.
      // Rendering a null scene is not the failure here — reporting the phase
      // complete before anything was drawn would be, because the curtain
      // would lift on the very stutter this exists to prevent.
      final queuer = _Recorder();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: GalleryPrimer(queuer: queuer),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
      expect(
        queuer.events,
        isEmpty,
        reason: 'it reported progress without having drawn a frame',
      );

      // And it keeps looking. The curtain waits on this phase, so a primer
      // that settles into "no scene yet" and stops asking does not merely
      // skip the warm-up — it strands the visitor behind a bar that never
      // fills, which is what happened at 89%.
      //
      // A pending frame callback is the evidence: `pump` completing without
      // the tree going idle means it asked to be built again.
      for (var frame = 0; frame < 3; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(
        tester.binding.hasScheduledFrame,
        isTrue,
        reason: 'it stopped watching for the scene and would never wake',
      );
      expect(queuer.events, isEmpty);
    });

    testWidgets('and a tree that is not watching does go quiet', (
      tester,
    ) async {
      // The control for the assertion above. `hasScheduledFrame` is only
      // evidence of watching if it is capable of being false — without this,
      // a binding that always reported true would make that test pass with
      // the watching removed, which is the one thing it exists to catch.
      await tester.pumpWidget(const SizedBox.shrink());
      for (var frame = 0; frame < 3; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    test('and priming is a phase of its own, so the bar can wait on it', () {
      // Without a phase there is nothing to wait through: `gallery` is the
      // heavy one and finishes last, so the scene becomes drawable at the
      // same moment the curtain starts to lift.
      expect(LoadingPhase.values, contains(LoadingPhase.priming));
      expect(
        LoadingPhase.priming.weight,
        lessThan(LoadingPhase.gallery.weight),
        reason: 'a handful of frames should not claim a builder share of the bar',
      );
      expect(LoadingPhase.priming.weight, greaterThan(0));
    });

    test('and it asks for more than one frame', () {
      // One frame compiles the pipelines, and is also the frame the
      // compiling makes slow. Stopping there hands its tail to the raster
      // thread exactly as the curtain lifts.
      expect(GalleryPrimer.warmFrames, greaterThan(1));
    });
  });
}
