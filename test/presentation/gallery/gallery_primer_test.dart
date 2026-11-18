import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/gallery_shape.dart';
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
      final camera = GalleryPrimer.entryCameraFor(GalleryShape.desktop);

      expect(camera.position, SceneAxes.position(pose.position));
      expect(camera.target, SceneAxes.position(pose.target));
    });

    test('and through the lens the room itself uses', () {
      // A different field of view is a different frustum, which is a
      // different set of nodes submitted — so the wrong pipelines again,
      // from a camera standing in exactly the right place.
      expect(
        GalleryPrimer.entryCameraFor(GalleryShape.desktop).fovRadiansY,
        GalleryDimensions.fovRadians,
      );
      expect(
        GalleryPrimer.entryCameraFor(GalleryShape.portrait).fovRadiansY,
        GalleryShape.portrait.fovRadians,
      );
    });

    test('it draws both ends of the path, entrance first', () {
      // Parked at the entrance alone, an earlier warm-up warmed the first
      // wall and nothing else: the scene culls against the frustum.
      expect(GalleryPrimer.progressFor(0), 0);
      expect(GalleryPrimer.progressFor(GalleryPrimer.walkFrames - 1), 1);
      for (var f = 1; f < GalleryPrimer.walkFrames; f++) {
        expect(
          GalleryPrimer.progressFor(f),
          greaterThan(GalleryPrimer.progressFor(f - 1)),
        );
      }
    });

    test('in two frames, because each one is loading time on a phone', () {
      // 28 full-size frames added 9.5 s to loading on the ROG; two left no
      // arrival stall (2026-11-17). More frames need a device measurement
      // that shows a stall these two leave behind.
      expect(GalleryPrimer.warmFrames, 2);
      expect(GalleryPrimer.settleFrames, 0);
    });

    test('the entry camera is the entrance, whatever the frame count', () {
      final entry = GalleryPrimer.entryCameraFor(GalleryShape.desktop);
      final first = GalleryPrimer.cameraFor(GalleryShape.desktop, 0);
      expect(entry.position, first.position);
      expect(entry.target, first.target);
    });

    test('a portrait phone walks the portrait path', () {
      // The board approach is keyed on the screen's aspect (Phone 6); a
      // landscape camera on a phone would warm a frustum it never sees.
      const portrait = 1080 / 2340;
      final last = GalleryPrimer.walkFrames - 1;
      final pose = GalleryCameraPath.poseAt(1, aspect: portrait);
      final camera = GalleryPrimer.cameraFor(
        GalleryShape.portrait,
        last,
        aspect: portrait,
      );

      expect(camera.position, SceneAxes.position(pose.position));
      expect(camera.target, SceneAxes.position(pose.target));
    });
  });

  group('it draws at the size the corridor will draw at', () {
    test('full screen, at the device pixel ratio, not a fraction', () {
      // A scene keeps one set of render targets per view and rebuilds them
      // whenever the drawn size changes. Primed at a twentieth of the pixels
      // (and again at one pixel during the title), the corridor's first frame
      // reallocated every full-size target in front of the visitor: a
      // 0.4-0.9 s stall on the ROG. The primer must ask for the same size the
      // gallery view asks for: the whole box, at the device's own ratio.
      final source = File(
        'lib/presentation/gallery/gallery_primer.dart',
      ).readAsStringSync();
      final code = source
          .split('\n')
          .where((line) => !line.trimLeft().startsWith('//'))
          .join('\n');
      final call = code.substring(code.indexOf('return SceneView('));

      expect(
        call.substring(0, call.indexOf('onTick')).contains('pixelRatio:'),
        isFalse,
        reason: 'the primer overrides the pixel ratio the corridor uses',
      );
    });

    test('and nothing else draws the gallery scene at another size', () {
      // The one-pixel warm render that ran during the title reset the
      // targets to one pixel, after the primer had made them full size.
      final users = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => f.readAsStringSync().contains('gallery.scene'))
          .map((f) => f.path.replaceAll(r'\', '/'))
          .toSet();

      expect(users, {
        'lib/presentation/gallery/gallery_primer.dart',
        'lib/presentation/gallery/gallery_view.dart',
      });
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
