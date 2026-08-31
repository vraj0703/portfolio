import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';
import 'package:portfolio/domain/radio/radio_player.dart';
import 'package:portfolio/domain/style/text_styles.dart';
import 'package:portfolio/presentation/gallery/radio_face.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const type = DefaultAppTypography();
  const state = RadioState(status: RadioStatus.off, station: 0);

  group('the face is cut like the rest of the room', () {
    test('is shaped to the panel it is stretched onto', () {
      // A face of the wrong proportions squashes every letter on it, and the
      // panel is the only thing that knows its own shape.
      final panel = GalleryLayout.build().firstWhere(
        (piece) => piece.kind == SurfaceKind.radio,
      );

      expect(
        RadioFace.width / RadioFace.height,
        closeTo(panel.extents.x / panel.extents.y, 0.01),
      );
    });

    test('leaves the marble showing between the letters', () async {
      // Engraved, like the signs — so most of this image is nothing at all.
      // Opaque, and the radio is a plate screwed to the wall.
      final image = await RadioFace.render(state: state, type: type);
      final bytes = (await image.toByteData())!;

      var opaque = 0;
      for (var i = 0; i < RadioFace.width * RadioFace.height; i++) {
        if (bytes.getUint8(i * 4 + 3) == 255) opaque++;
      }

      // The gold inlay fills the letterforms; nothing else should. The
      // bound is loose on purpose: it is guarding against the face turning
      // into a filled rectangle, which would read near 1, not measuring how
      // much of it the lettering takes. It cannot be tight in any case —
      // these tests run without the real fonts, so the glyphs here are a
      // fallback's and wider than Marcellus's.
      final inked = opaque / (RadioFace.width * RadioFace.height);
      expect(inked, greaterThan(0), reason: 'nothing was cut');
      expect(inked, lessThan(0.4), reason: 'the face is a plate, not lettering');
      image.dispose();
    });
  });

  group('the picture and the promise agree', () {
    test('the controls are drawn where a finger has to land', () async {
      // The face is a bitmap and the tap targets are geometry; nothing forces
      // them to match. This renders the face, finds the row the controls
      // actually landed on, and checks the target sits inside it — rather
      // than comparing two constants, which agree by construction and prove
      // nothing about where the text ended up.
      final image = await RadioFace.render(state: state, type: type);
      final bytes = (await image.toByteData())!;

      bool inkOn(int y) {
        for (var x = 0; x < RadioFace.width; x++) {
          if (bytes.getUint8((y * RadioFace.width + x) * 4 + 3) > 0) {
            return true;
          }
        }
        return false;
      }

      // The lowest band of ink is the controls: they are the last row.
      var bottom = -1;
      for (var y = RadioFace.height - 1; y >= 0; y--) {
        if (inkOn(y)) {
          bottom = y;
          break;
        }
      }
      expect(bottom, greaterThan(0), reason: 'nothing was drawn');

      var top = bottom;
      while (top > 0 && inkOn(top - 1)) {
        top--;
      }

      // Where that band sits on the panel, measured down from its middle.
      final panel = GalleryLayout.build().firstWhere(
        (piece) => piece.kind == SurfaceKind.radio,
      );
      final middle = (top + bottom) / 2 / RadioFace.height;
      final drawnBelowMiddle = (middle - 0.5) * panel.extents.y;

      expect(
        GalleryLayout.radioButtonDrop,
        closeTo(drawnBelowMiddle, GalleryLayout.radioButtonSize / 2),
        reason: 'the tap targets miss the row the controls are drawn on',
      );
      image.dispose();
    });

    test('the station name is drawn where the room hangs it by', () async {
      // The hall hangs its radio by [radioStationAt] so the name lines up
      // with the invitation across the door. That number describes a row in
      // an image nothing forces it to match — so this finds the row the name
      // actually landed on and checks the two still agree. Get it wrong and
      // nothing breaks; the two signs just sit at different heights again.
      final image = await RadioFace.render(state: state, type: type);
      final bytes = (await image.toByteData())!;

      bool inkOn(int y) {
        for (var x = 0; x < RadioFace.width; x++) {
          if (bytes.getUint8((y * RadioFace.width + x) * 4 + 3) > 0) {
            return true;
          }
        }
        return false;
      }

      // The highest band of ink is the station: it is the first row.
      var top = -1;
      for (var y = 0; y < RadioFace.height; y++) {
        if (inkOn(y)) {
          top = y;
          break;
        }
      }
      expect(top, greaterThanOrEqualTo(0), reason: 'nothing was drawn');

      var bottom = top;
      while (bottom < RadioFace.height - 1 && inkOn(bottom + 1)) {
        bottom++;
      }

      final drawnAt = (top + bottom) / 2 / RadioFace.height;

      // Loose by a fraction of a letter, because the constant describes the
      // line's box and this measures its ink — a cap sits a little above the
      // middle of the space the line reserves. Tight enough to catch the
      // name having moved to a different row.
      expect(
        GalleryLayout.radioStationAt,
        closeTo(drawnAt, 0.06),
        reason: 'the name is not on the row the hall hangs it by',
      );
      image.dispose();
    });

    test('and the play control says what pressing it will do', () async {
      // Not what the radio is doing. A button labelled with the current
      // state reads as a description until somebody presses it to find out.
      final off = await RadioFace.render(state: state, type: type);
      final on = await RadioFace.render(
        state: state.copyWith(status: RadioStatus.onAir),
        type: type,
      );

      final a = (await off.toByteData())!;
      final b = (await on.toByteData())!;

      var differing = 0;
      for (var i = 0; i < RadioFace.width * RadioFace.height; i++) {
        if (a.getUint8(i * 4 + 3) != b.getUint8(i * 4 + 3)) differing++;
      }

      expect(differing, greaterThan(0), reason: 'the face never changes');
      off.dispose();
      on.dispose();
    });
  });
}
