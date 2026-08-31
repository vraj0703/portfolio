import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/radio/radio_player.dart';
import 'package:portfolio/domain/radio/radio_station.dart';

void main() {
  group('the dial', () {
    test('carries the stations the previous site had', () {
      expect(RadioDial.stations, hasLength(4));
      expect(
        RadioDial.stations.map((s) => s.name),
        <String>['Lofi', 'Jazz', 'Ambient', 'Chill'],
      );
    });

    test('rests on the one the room is named for', () {
      expect(RadioDial.at(RadioDial.first).name, 'Lofi');
    });

    test('wraps rather than running out', () {
      // One button steps the dial and it is the only way through the
      // stations, so an end would leave the visitor unable to get back to
      // the first.
      var index = RadioDial.first;
      final visited = <String>[];

      for (var i = 0; i < RadioDial.stations.length; i++) {
        visited.add(RadioDial.at(index).name);
        index = RadioDial.next(index);
      }

      expect(visited.toSet(), hasLength(RadioDial.stations.length));
      expect(index, RadioDial.first, reason: 'the dial did not come round');
    });

    test('reads an index past the end rather than throwing', () {
      // `at` is handed whatever the state holds, and a state that outlived a
      // station being removed should quietly show a real station instead of
      // taking the room down.
      expect(RadioDial.at(RadioDial.stations.length).name, 'Lofi');
      expect(RadioDial.at(99), isNotNull);
    });

    test('every station names somewhere to fetch from', () {
      for (final station in RadioDial.stations) {
        expect(station.name, isNotEmpty);
        expect(station.stream.hasScheme, isTrue, reason: station.name);
        expect(
          station.stream.scheme,
          'https',
          // A page served over https will not open a plaintext stream — the
          // browser blocks it as mixed content, and the radio is silent for
          // a reason nothing in the app can see.
          reason: '${station.name} would be blocked as mixed content',
        );
      }
    });
  });

  group('what the wall reads', () {
    test('says something for every state the radio can be in', () {
      // A missing readout is a blank panel, which looks like the radio being
      // broken rather than being off.
      for (final status in RadioStatus.values) {
        expect(RadioState.readouts[status], isNotNull, reason: '$status');
        expect(RadioState.readouts[status], isNotEmpty, reason: '$status');
      }
    });

    test('tells "coming" apart from "you did not press it"', () {
      // The reason tuning is a state of its own. Opening a stream can take
      // several seconds, and a control that looks unpressed for that long
      // gets pressed again.
      const off = RadioState(status: RadioStatus.off, station: 0);
      const tuning = RadioState(status: RadioStatus.tuning, station: 0);

      expect(off.readout, isNot(tuning.readout));
      expect(tuning.isTuning, isTrue);
      expect(tuning.isPlaying, isFalse);
    });
  });

  group('the state it carries', () {
    const base = RadioState(status: RadioStatus.off, station: 0);

    test('starts quiet enough to sit under the room', () {
      // It plays beneath a gallery the visitor came to look at, not over it.
      expect(RadioState.defaultVolume, lessThan(0.4));
      expect(RadioState.defaultVolume, greaterThan(0));
      expect(base.volume, RadioState.defaultVolume);
      expect(base.muted, isFalse);
    });

    test('compares by value, so an unchanged state raises nothing', () {
      // The player only emits on a real change; without this every call
      // would wake every listener.
      expect(base.copyWith(), base);
      expect(base.copyWith(status: RadioStatus.onAir), isNot(base));
      expect(base.copyWith(station: 1), isNot(base));
      expect(base.copyWith(volume: 0.9), isNot(base));
      expect(base.copyWith(muted: true), isNot(base));
    });

    test('and knows which station it is on', () {
      expect(base.copyWith(station: 1).tuned.name, RadioDial.at(1).name);
    });
  });
}
