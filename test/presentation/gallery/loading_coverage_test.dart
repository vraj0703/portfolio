import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/presentation/gallery/texture_sets.dart';

void main() {
  // Every set the gallery builds. If one is added and not loaded through the
  // reporting path, the bar goes quiet for however long it takes.
  const sets = <String, TextureSet>{
    'floor': GallerySurfaces.floor,
    'wall': GallerySurfaces.wall,
    'ceiling': GallerySurfaces.ceiling,
    'frame': GallerySurfaces.frame,
    'testimonialFrame': GallerySurfaces.testimonialFrame,
    'keyboardBase': GallerySurfaces.keyboardBase,
  };

  test('every set reports one step per file, decoded and uploaded', () {
    // The denominator the bar divides by. Counting only decodes is what left
    // it silent through every upload the first time round.
    for (final entry in sets.entries) {
      expect(
        entry.value.stepCount,
        entry.value.mapCount * 2,
        reason: entry.key,
      );
    }
  });

  test('a metalness map costs a decode but not an upload', () {
    // It is folded into the roughness map's blue channel rather than bound
    // as a texture of its own, so counting it twice would make the bar
    // finish early and then wait.
    for (final set in GallerySurfaces.keyRows) {
      expect(set.metalness, isNotNull);
      expect(set.stepCount, set.mapCount * 2 + 1);
    }
  });

  test('the keycap rows are three distinct metals', () {
    // Different alloys per row do the job the original's row tints did:
    // showing the board is grouped without putting a label on it.
    final colours = GallerySurfaces.keyRows.map((s) => s.colour).toSet();
    expect(colours, hasLength(3));
  });

  test('the board is surfaced like everything else in the room', () {
    // It used to be the one object built with a flat colour, so none of its
    // loading was accounted for.
    expect(GallerySurfaces.keyboardBase.normal, isNotNull);
    expect(GallerySurfaces.keyboardBase.metallic, 1);
  });

  test('the keyboard case tiles far longer than the frames', () {
    // Same reasoning either way: a moulding a few centimetres across wants
    // fine grain, a single milled block wants almost none.
    expect(
      GallerySurfaces.keyboardBase.unitsPerRepeat,
      greaterThan(GallerySurfaces.frame.unitsPerRepeat * 3),
    );
  });
}
