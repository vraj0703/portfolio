/// One station the wall radio can be tuned to.
class RadioStation {
  const RadioStation({required this.name, required this.stream});

  /// What the dial reads. Short, because it is lettered on a wall.
  final String name;

  /// Where the audio comes from.
  ///
  /// Somebody else's server. That is worth stating plainly: the radio is the
  /// one thing in this room that depends on a service nobody here runs, so
  /// every part of it has to survive that service being down, slow, or
  /// blocked — see `RadioPlayer`.
  final Uri stream;
}

/// The stations, in the order the dial steps through them.
///
/// Carried over from the previous site, which took all four from SomaFM.
/// Kept as data rather than built into the player so the order and the
/// wrapping can be checked without a network or a speaker.
abstract final class RadioDial {
  static final List<RadioStation> stations = <RadioStation>[
    RadioStation(
      name: 'Lofi',
      stream: Uri.parse('https://ice5.somafm.com/lush-128-mp3'),
    ),
    RadioStation(
      name: 'Jazz',
      stream: Uri.parse('https://ice4.somafm.com/secretagent-128-mp3'),
    ),
    RadioStation(
      name: 'Ambient',
      stream: Uri.parse('https://ice5.somafm.com/groovesalad-128-mp3'),
    ),
    RadioStation(
      name: 'Chill',
      stream: Uri.parse('https://ice2.somafm.com/seventies-128-mp3'),
    ),
  ];

  /// Where the dial rests when the visitor first arrives.
  static const int first = 0;

  /// The station after [index], wrapping round.
  ///
  /// A dial rather than a list with an end: the visitor presses one button
  /// and it is the only way through the stations, so running out at the last
  /// one would leave them with no way back to the first.
  static int next(int index) => (index + 1) % stations.length;

  static RadioStation at(int index) => stations[index % stations.length];
}
