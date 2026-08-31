/// One line of the credits: a heading and what sits under it.
class CreditGroup {
  const CreditGroup({required this.heading, required this.items});

  final String heading;
  final List<String> items;
}

/// What this room was built out of.
///
/// Kept as data next to the menu that opens it rather than written into the
/// dialog, for the ordinary reason: the list grows every time something new
/// is pulled in, and a list that lives in a widget is a list that stops being
/// updated. Everything here is used by the running scene — nothing is
/// credited that was not.
abstract final class Credits {
  static const List<CreditGroup> groups = <CreditGroup>[
    CreditGroup(
      heading: 'Surfaces',
      items: <String>[
        'ambientCG — tiles, marble, timber and the alloys on the keyboard',
        'Poly Haven — environment lighting',
      ],
    ),
    CreditGroup(
      heading: 'Type',
      items: <String>[
        'Apertura — the titles',
        'Modrnt Urban — the mark',
        'MonoLoading — the loading readout',
      ],
    ),
    CreditGroup(
      heading: 'On the air',
      items: <String>[
        'SomaFM — every station the wall radio is tuned to',
      ],
    ),
    CreditGroup(
      heading: 'Built with',
      items: <String>[
        'Flutter — the whole of it',
        'Flame — the title scene',
        'flutter_scene — the gallery and the skills hall',
        'flutter_bloc & freezed — the state it all runs on',
        'flutter_svg, url_launcher — the marks on this menu, and its links',
      ],
    ),
  ];
}
