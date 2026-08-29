/// Where one entry on the contact menu leads.
///
/// An enum rather than a callback per entry, so the menu itself stays data.
/// The arrangement — which entries there are and what order they read in — is
/// the part worth checking without a renderer, and the part most likely to be
/// got wrong: the gallery mark belongs before the words and the home mark
/// after the heart, and neither is visible as a mistake from inside a running
/// scene.
enum ContactDestination {
  /// Back into the corridor, at the entrance rather than where they left it.
  gallery,

  /// The résumé, as a download.
  cv,

  /// Hands off to whatever the visitor writes mail with.
  email,

  github,

  linkedin,

  /// The credits: what this was built out of, and by whom.
  credits,

  /// The title screen, as though the visitor had just tapped in.
  home,
}

/// One entry, as it is read.
class ContactEntry {
  const ContactEntry({required this.destination, this.icon});

  final ContactDestination destination;

  /// Asset path, for an entry that draws a mark.
  ///
  /// The three that carry one are the entries that are *not* about reaching
  /// Vishal — where you came from, what this is made of, and the way out.
  /// Drawing them as glyphs is what separates them from the four that are.
  final String? icon;

  bool get isMark => icon != null;

  /// Whether the entry reads as words before its mark.
  ///
  /// Only the credits do. The heart alone was a rebus — a shape the visitor
  /// has to guess the meaning of, sitting in a row where every other entry
  /// says what it is. "Made with ♥" says it and keeps the mark.
  bool get hasWords => destination == ContactDestination.credits;
}

/// The horizontal menu that stands in for "TAP TO ENTER" on the contact
/// screen.
abstract final class ContactMenu {
  static const String galleryIcon = 'assets/vectors/gallery.svg';
  static const String heartIcon = 'assets/vectors/heart.svg';
  static const String homeIcon = 'assets/vectors/home.svg';

  /// The dot between one destination and the next.
  ///
  /// Drawn rather than typed. A middot is a *glyph*, so its size, its weight
  /// and where it sits on the line are all decided by the typeface — and at
  /// the size the menu is set in it comes out as a smudge sitting high.
  static const String separatorIcon = 'assets/vectors/circle.svg';

  static const List<String> icons = <String>[
    galleryIcon,
    heartIcon,
    homeIcon,
  ];

  /// Every drawing the menu needs, marks and punctuation alike.
  static const List<String> drawings = <String>[...icons, separatorIcon];

  static const List<ContactEntry> entries = <ContactEntry>[
    ContactEntry(destination: ContactDestination.gallery, icon: galleryIcon),
    ContactEntry(destination: ContactDestination.cv),
    ContactEntry(destination: ContactDestination.email),
    ContactEntry(destination: ContactDestination.github),
    ContactEntry(destination: ContactDestination.linkedin),
    ContactEntry(destination: ContactDestination.credits, icon: heartIcon),
    ContactEntry(destination: ContactDestination.home, icon: homeIcon),
  ];
}
