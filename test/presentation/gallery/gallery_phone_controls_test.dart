import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/gallery_camera_path.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';
import 'package:portfolio/domain/gallery/gallery_shape.dart';
import 'package:portfolio/presentation/gallery/gallery_phone_controls.dart';

/// Whether [piece] is inside the camera's horizontal field of view at the
/// start of the walk, for a screen of [aspect] (width over height).
bool inViewAtStart(Placement piece, GalleryShape shape, double aspect) {
  final pose = GalleryCameraPath.poseAt(0, aspect: aspect);
  final ahead = (pose.target - pose.position)..y = 0;
  final toPiece = (piece.position - pose.position)..y = 0;
  final angle = math.acos(
    ahead.normalized().dot(toPiece.normalized()).clamp(-1.0, 1.0),
  );
  final halfWidth = math.atan(math.tan(shape.fovRadians / 2) * aspect);
  return angle < halfWidth;
}

void main() {
  group('why a phone needs the row', () {
    const phone = 1080 / 2005; // the ROG's gallery view, at DPR 2
    const laptop = 16 / 9;

    Placement entrance(GalleryShape shape, SurfaceKind kind) =>
        GalleryLayout.build(
          shape: shape,
        ).firstWhere((p) => p.kind == kind && p.position.z > -2);

    test(
      'on a portrait phone the BACK sign and the radio start out of view',
      () {
        // Reported on Vishal's phone: neither could be seen, so neither could
        // be pressed. They hang 39 degrees off the corridor's line; a portrait
        // camera sees about 24 either side.
        const shape = GalleryShape.portrait;
        for (final kind in <SurfaceKind>[
          SurfaceKind.exitSign,
          SurfaceKind.radio,
        ]) {
          expect(
            inViewAtStart(entrance(shape, kind), shape, phone),
            isFalse,
            reason: '$kind',
          );
        }
      },
    );

    test('a laptop sees both, so it keeps the wall pieces alone', () {
      const shape = GalleryShape.desktop;
      for (final kind in <SurfaceKind>[
        SurfaceKind.exitSign,
        SurfaceKind.radio,
      ]) {
        expect(
          inViewAtStart(entrance(shape, kind), shape, laptop),
          isTrue,
          reason: '$kind',
        );
      }
    });
  });

  testWidgets('the row does what the wall pieces do', (tester) async {
    final taps = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GalleryPhoneControls(
            onBack: () => taps.add('back'),
            onRadio: () => taps.add('radio'),
            onRadioNext: () => taps.add('next'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('‹'));
    await tester.tap(find.text('♪'));
    await tester.tap(find.text('»'));
    expect(taps, <String>['back', 'radio', 'next']);
    expect(find.bySemanticsLabel(RegExp('BACK')), findsOneWidget);
  });

  test('the gallery shows it on portrait only, wired to the wall handlers', () {
    final source = File(
      'lib/presentation/gallery/gallery_view.dart',
    ).readAsStringSync();
    expect(source, contains('if (_shape == GalleryShape.portrait)'));
    expect(source, contains('onBack: _exitGallery'));
    expect(source, contains('onRadio: _toggleRadio'));
    expect(source, contains('onRadioNext: _nextStation'));
  });
}
