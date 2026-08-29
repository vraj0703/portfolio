import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/presentation/gallery/texture_sets.dart';

void main() {
  /// Every set the gallery builds, named.
  const sets = <String, TextureSet>{
    'floor': GallerySurfaces.floor,
    'wall': GallerySurfaces.wall,
    'frame': GallerySurfaces.frame,
    'testimonialFrame': GallerySurfaces.testimonialFrame,
    'keyboardBase': GallerySurfaces.keyboardBase,
    'ceiling': GallerySurfaces.ceiling,
  };

  test('every declared set is loaded through the reporting path', () {
    // The bar divides by a count taken before the work starts, so a set that
    // is loaded without reporting does not make the bar wrong — it makes it
    // *stop*, which reads as the site having died. This has happened twice:
    // once when the artwork steps were deleted with the artwork, and once
    // when the board and its metals were added without being counted.
    final source = File(
      'lib/presentation/gallery/gallery_scene_builder.dart',
    ).readAsStringSync();

    for (final name in <String>[...sets.keys, 'keyRows']) {
      expect(
        source.contains('GallerySurfaces.$name'),
        isTrue,
        reason: '$name is declared but the builder never loads it',
      );
    }

    // Every load in the builder passes a step reporter. A bare `load(` with
    // no `onStep` is a stretch of silence.
    final loads = RegExp(
      r'SurfaceMaps\.load\((?:[^()]|\([^()]*\))*\)',
      dotAll: true,
    ).allMatches(source);

    expect(loads, isNotEmpty);
    for (final load in loads) {
      expect(
        load.group(0),
        contains('onStep'),
        reason: 'a texture set loads without reporting progress',
      );
    }
  });

  test('the tail is counted, and counts what is actually there', () {
    // Statement, arrow, three control models, the board's case, the three
    // keycap metals, and the board. Written out rather than asserted against
    // a constant, so the two have to be reconciled by hand when either moves.
    const statement = 1;
    const arrow = 1;
    const controls = 3;
    final base = GallerySurfaces.keyboardBase.stepCount;
    final keys = GallerySurfaces.keyRows
        .map((s) => s.stepCount)
        .reduce((a, b) => a + b);
    const board = 1;

    final source = File(
      'lib/presentation/gallery/gallery_scene_builder.dart',
    ).readAsStringSync();
    final declared = RegExp(r'_tailSteps = (\d+)').firstMatch(source);

    expect(declared, isNotNull);
    expect(
      int.parse(declared!.group(1)!),
      statement + arrow + controls + base + keys + board,
    );
  });
}
