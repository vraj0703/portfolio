import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/radio/radio_player.dart';
import 'package:portfolio/domain/radio/radio_station.dart';
import 'package:portfolio/presentation/gallery/wall_radio.dart';

void main() {
  const off = RadioState(status: RadioStatus.off, station: RadioDial.first);

  group('a face is a function of the state that draws it', () {
    test('and the same state asks for the same face', () {
      // The cache is what keeps a change cheap. Rendering one face costs
      // about 450ms and reading it back for upload another 490ms, so a key
      // that missed when it should have hit would put a second of frozen
      // scroll back into the corridor.
      expect(WallRadios.faceKey(off), WallRadios.faceKey(off));
    });

    test('a different readout is a different face', () {
      expect(
        WallRadios.faceKey(off.copyWith(status: RadioStatus.onAir)),
        isNot(WallRadios.faceKey(off)),
      );
    });

    test('and so is a different station', () {
      // The station name is lettered onto the face. A key that ignored it
      // would hang JAZZ under LOFI's picture.
      expect(
        WallRadios.faceKey(off.copyWith(station: 2)),
        isNot(WallRadios.faceKey(off)),
      );
    });
  });

  group('but not of things the face does not draw', () {
    test('turning it down does not ask for a new face', () {
      // Volume and mute change the radio without changing its picture.
      // Keying on them would rebake a face already on the wall.
      expect(
        WallRadios.faceKey(off.copyWith(volume: 0.9)),
        WallRadios.faceKey(off),
      );
      expect(
        WallRadios.faceKey(off.copyWith(muted: true)),
        WallRadios.faceKey(off),
      );
    });
  });

  group('the space it has to cover is small enough to keep', () {
    test('every status of every station', () {
      // Never evicted, so it is worth knowing the whole space fits: a
      // texture already on the GPU costs nothing to keep and most of a
      // second to rebuild.
      final keys = <String>{
        for (var station = 0; station < RadioDial.stations.length; station++)
          for (final status in RadioStatus.values)
            WallRadios.faceKey(
              RadioState(status: status, station: station),
            ),
      };

      expect(keys, hasLength(RadioDial.stations.length * RadioStatus.values.length));
      expect(keys.length, lessThan(20), reason: 'too many faces to hold');
    });
  });
}
