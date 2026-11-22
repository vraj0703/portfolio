/// One line of the credits dialog: a heading and what sits under it.
class CreditGroup {
  const CreditGroup({required this.heading, required this.items});

  final String heading;
  final List<String> items;
}

/// Whether the work's owner asks for credit, or it is given anyway.
enum CreditNeed {
  /// The licence asks for it.
  required,

  /// Not asked for; given as thanks.
  courtesy,

  /// Ours, or a service: nothing to credit.
  none,
}

/// Whether the author and the licence are known. An unknown item is listed
/// in docs/CREDITS.md and left out of the dialog until Vishal answers.
enum CreditStatus { known, unknown }

/// One thing this site is made of (PORTFOLIO-31).
class CreditItem {
  const CreditItem({
    required this.what,
    required this.usedFor,
    required this.author,
    required this.licence,
    required this.link,
    required this.need,
    required this.status,
    this.paths = const <String>[],
    this.heading,
    this.line,
  });

  final String what;
  final String usedFor;
  final String author;
  final String licence;
  final String link;
  final CreditNeed need;
  final CreditStatus status;

  /// The repository paths it covers: a file, or a folder ending in `/`.
  final List<String> paths;

  /// Where it stands in the dialog, and the line it is given there; null
  /// for an item the dialog does not show.
  final String? heading;
  final String? line;

  /// Whether [path] (a repository path) is this item's.
  bool covers(String path) =>
      paths.any((p) => p.endsWith('/') ? path.startsWith(p) : path == p);
}

/// What this site is made of, and whose it is: the one record. The
/// "Made with heart" dialog is generated from it ([groups]) and
/// docs/CREDITS.md mirrors it row for row (a test keeps the two in step,
/// and fails if any file under assets/ or fonts/ has no entry).
///
/// Nothing is invented here: what is not known says so and stays out of the
/// dialog until Vishal answers (the questions are in PORTFOLIO-31).
abstract final class Credits {
  static const String unknown = 'UNKNOWN';

  static const List<CreditItem> items = <CreditItem>[
    // -- Made here ------------------------------------------------------
    CreditItem(
      what: 'The code',
      usedFor: 'the whole site',
      author: "written with Claude (Anthropic) under Vishal Raj's direction",
      licence: "Vishal Raj's",
      link: '',
      need: CreditNeed.none,
      status: CreditStatus.known,
    ),
    CreditItem(
      what: 'Logo and mark (logo.png)',
      usedFor: 'everywhere',
      author: 'Vishal Raj, drawn by hand, without AI',
      licence: 'his own',
      link: '',
      need: CreditNeed.none,
      status: CreditStatus.known,
      paths: <String>['assets/images/logo.png'],
    ),
    CreditItem(
      what: 'Close icon (close.svg)',
      usedFor: 'the drawer and the dialogs',
      author: 'Shunya Systems (PORTFOLIO-26)',
      licence: 'our own',
      link: '',
      need: CreditNeed.none,
      status: CreditStatus.known,
      paths: <String>['assets/vectors/close.svg'],
    ),
    CreditItem(
      what: "Frame captures (the projects' own sites)",
      usedFor: 'the gallery frames (PORTFOLIO-6)',
      author: 'captured from our own sites by tool/capture_frame.py',
      licence: 'our own',
      link: '',
      need: CreditNeed.none,
      status: CreditStatus.known,
      paths: <String>['assets/frames/'],
    ),

    // -- Surfaces -------------------------------------------------------
    CreditItem(
      what:
          'ambientCG textures: Tiles013, Marble004, Wood066, Wood020, '
          'OfficeCeiling001, Metal048B, Metal023, Metal056B, Metal022, '
          'Metal008',
      usedFor: 'floor, walls, frames, testimonial frames, ceiling, keyboard',
      author: 'ambientCG (Lennart Demes)',
      licence: 'CC0 1.0',
      link: 'https://docs.ambientcg.com/license/',
      need: CreditNeed.courtesy,
      status: CreditStatus.known,
      paths: <String>['assets/textures/'],
      heading: 'Surfaces',
      line: 'ambientCG — tiles, marble, timber and the alloys on the keyboard',
    ),

    // -- Type -----------------------------------------------------------
    CreditItem(
      what: 'Font Marcellus',
      usedFor: 'the radio lettering',
      author: 'Astigmatic',
      licence: 'SIL Open Font License 1.1',
      link: 'https://github.com/google/fonts/tree/main/ofl/marcellus',
      need: CreditNeed.courtesy,
      status: CreditStatus.known,
      paths: <String>['fonts/marcellus.ttf'],
      heading: 'Type',
      line: 'Marcellus by Astigmatic — the radio lettering',
    ),
    CreditItem(
      what: 'Font Azeret Mono',
      usedFor: 'mono text',
      author: 'Displaay, Martin Vácha',
      licence: 'SIL Open Font License 1.1',
      link: 'https://github.com/google/fonts/tree/main/ofl/azeretmono',
      need: CreditNeed.courtesy,
      status: CreditStatus.known,
      paths: <String>['fonts/azeretmono.ttf'],
      heading: 'Type',
      line: 'Azeret Mono by Displaay — the mono text',
    ),
    CreditItem(
      what: 'Font Apertura',
      usedFor: 'the titles',
      author: unknown,
      licence: unknown,
      link: '',
      need: CreditNeed.courtesy,
      status: CreditStatus.unknown,
      paths: <String>['fonts/aperturaregular.ttf'],
    ),
    CreditItem(
      what: 'Font Modrnt Urban',
      usedFor: "the mark's lettering",
      author: unknown,
      licence: unknown,
      link: '',
      need: CreditNeed.courtesy,
      status: CreditStatus.unknown,
      paths: <String>['fonts/modrnt_urban.otf'],
    ),
    CreditItem(
      what: 'Font MonoLoading',
      usedFor: 'the loading readout',
      author: unknown,
      licence: unknown,
      link: '',
      need: CreditNeed.courtesy,
      status: CreditStatus.unknown,
      paths: <String>['fonts/mono_loading.ttf'],
    ),
    CreditItem(
      what: 'Font Margot (Regular, Bold)',
      usedFor: "most of the site's text",
      author: unknown,
      licence: unknown,
      link: '',
      need: CreditNeed.courtesy,
      status: CreditStatus.unknown,
      paths: <String>['fonts/Margot-Regular.ttf', 'fonts/Margot-Bold.ttf'],
    ),

    // -- Sound and icons ------------------------------------------------
    CreditItem(
      what: 'Sound effects (17 files)',
      usedFor: 'clicks, entries, key strokes, page turns, the title swell',
      author: 'Pixabay contributors',
      licence: 'Pixabay Content License (credit not required)',
      link: 'https://pixabay.com/service/license-summary/',
      need: CreditNeed.courtesy,
      status: CreditStatus.known,
      paths: <String>['assets/audio/'],
      heading: 'Sound',
      line: 'Pixabay — the interface sounds',
    ),
    CreditItem(
      what: 'Icons: speaker, mute, heart, menu, home, gallery',
      usedFor: 'the top row, the drawer bar, the contact links',
      author: 'IconScout contributors (designer not yet named)',
      licence: 'IconScout licence (attribution encouraged, not required)',
      link: 'https://iconscout.com/licenses',
      need: CreditNeed.courtesy,
      status: CreditStatus.known,
      paths: <String>[
        'assets/vectors/speaker.svg',
        'assets/vectors/mute.svg',
        'assets/vectors/heart.svg',
        'assets/vectors/menu.svg',
        'assets/vectors/home.svg',
        'assets/vectors/gallery.svg',
      ],
      heading: 'Icons',
      line: 'IconScout — the icons on the menus',
    ),
    CreditItem(
      what: 'Separator dot (circle.svg)',
      usedFor: 'between the contact links',
      author: unknown,
      licence: unknown,
      link: '',
      need: CreditNeed.courtesy,
      status: CreditStatus.unknown,
      paths: <String>['assets/vectors/circle.svg'],
    ),

    // -- Not yet known --------------------------------------------------
    CreditItem(
      what:
          'Shaders: background_run_v2, god_rays, logo, metallic_text, '
          'bold_text_entrance (one is said to be from Shadertoy)',
      usedFor:
          'the title backdrop, the logo rays, the mark, the name, '
          'the bold text',
      author: unknown,
      licence: unknown,
      link: '',
      need: CreditNeed.courtesy,
      status: CreditStatus.unknown,
      paths: <String>['assets/shaders/'],
    ),
    CreditItem(
      what: 'Models: arrow.glb, cross.glb, direction_arrow.glb',
      usedFor: "the gallery's arrows and the close cross",
      author: unknown,
      licence: unknown,
      link: '',
      need: CreditNeed.courtesy,
      status: CreditStatus.unknown,
      paths: <String>['assets/objects/'],
    ),
    CreditItem(
      what: 'Share image (og-image.jpg)',
      usedFor: "the picture shown when the site's link is shared",
      author: unknown,
      licence: unknown,
      link: '',
      need: CreditNeed.courtesy,
      status: CreditStatus.unknown,
      paths: <String>['web/og-image.jpg'],
    ),

    // -- On the air -----------------------------------------------------
    CreditItem(
      what: 'Radio streams',
      usedFor: 'the radio',
      author: 'SomaFM',
      licence: "SomaFM's terms for linking to its streams",
      link: 'https://somafm.com/linktous/',
      need: CreditNeed.required,
      status: CreditStatus.known,
      heading: 'On the air',
      line: 'SomaFM — every station the wall radio is tuned to',
    ),

    // -- Built with -----------------------------------------------------
    CreditItem(
      what: 'Flutter',
      usedFor: 'the whole site',
      author: 'Google and the Flutter authors',
      licence: 'BSD 3-Clause',
      link: 'https://github.com/flutter/flutter/blob/master/LICENSE',
      need: CreditNeed.courtesy,
      status: CreditStatus.known,
      heading: 'Built with',
      line: 'Flutter — the whole of it',
    ),
    CreditItem(
      what: 'Skia / CanvasKit (the web renderer)',
      usedFor: 'every frame drawn on the web',
      author: 'Google and the Skia authors',
      licence: 'BSD 3-Clause',
      link: 'https://skia.org/',
      need: CreditNeed.courtesy,
      status: CreditStatus.known,
    ),
    CreditItem(
      what: 'Flame, flame_audio, flame_svg, flame_bloc',
      usedFor: 'the title scene and its sounds',
      author: 'Blue Fire (flame-engine.org)',
      licence: 'MIT',
      link: 'https://pub.dev/packages/flame',
      need: CreditNeed.courtesy,
      status: CreditStatus.known,
      heading: 'Built with',
      line: 'Flame — the title scene',
    ),
    CreditItem(
      what: 'flutter_scene',
      usedFor: 'the gallery and the skills hall',
      author: 'Brandon DeRosier (bdero.dev)',
      licence: 'MIT',
      link: 'https://pub.dev/packages/flutter_scene',
      need: CreditNeed.courtesy,
      status: CreditStatus.known,
      heading: 'Built with',
      line: 'flutter_scene — the gallery and the skills hall',
    ),
    CreditItem(
      what: 'flutter_bloc, freezed',
      usedFor: 'the state it all runs on',
      author: 'Felix Angelov (bloclibrary.dev); Remi Rousselet',
      licence: 'MIT',
      link: 'https://pub.dev/packages/flutter_bloc',
      need: CreditNeed.courtesy,
      status: CreditStatus.known,
      heading: 'Built with',
      line: 'flutter_bloc & freezed — the state it all runs on',
    ),
    CreditItem(
      what: 'flutter_svg, url_launcher',
      usedFor: 'the marks on the menus, and their links',
      author: 'the Flutter team',
      licence: 'MIT (flutter_svg); BSD 3-Clause (url_launcher)',
      link: 'https://pub.dev/packages/flutter_svg',
      need: CreditNeed.courtesy,
      status: CreditStatus.known,
      heading: 'Built with',
      line: 'flutter_svg, url_launcher — the marks on this menu, and its links',
    ),
    CreditItem(
      what: 'vector_math, web, cupertino_icons',
      usedFor: 'maths, browser calls; a default dependency',
      author: 'the Flutter and Dart teams',
      licence: 'BSD 3-Clause (vector_math, web); MIT (cupertino_icons)',
      link: 'https://pub.dev/packages/vector_math',
      need: CreditNeed.courtesy,
      status: CreditStatus.known,
    ),

    // -- Services -------------------------------------------------------
    CreditItem(
      what: 'PostHog (analytics), Firebase Hosting',
      usedFor: 'services the page uses',
      author: 'PostHog Inc.; Google',
      licence: 'service terms, not assets',
      link: 'https://posthog.com',
      need: CreditNeed.none,
      status: CreditStatus.known,
    ),
  ];

  /// docs/CREDITS.md, rendered from [items] (`dart run tool/write_credits.dart`
  /// writes it; a test fails when the file and this differ).
  static String markdown() {
    String cell(String v) => v.isEmpty ? '' : v.replaceAll('|', '/');
    final b = StringBuffer()
      ..writeln('# Credits')
      ..writeln()
      ..writeln(
        'What this site is made of, and whose it is. Generated from '
        '`lib/domain/contact/credits.dart` by `dart run tool/write_credits.dart`; '
        'the "Made with heart" dialog is generated from the same record. '
        'UNKNOWN means not yet answered (PORTFOLIO-31): such items stay out of '
        'the dialog until they are.',
      )
      ..writeln()
      ..writeln(
        '| What | Where used | Author / source | Link | Licence | Credit | Status | Files |',
      )
      ..writeln('|---|---|---|---|---|---|---|---|');
    for (final i in items) {
      final credit = switch (i.need) {
        CreditNeed.required => 'required',
        CreditNeed.courtesy => 'courtesy',
        CreditNeed.none => 'none',
      };
      final status = i.status == CreditStatus.known ? 'known' : '**UNKNOWN**';
      final files = i.paths.map((p) => '`$p`').join(', ');
      b.writeln(
        '| ${cell(i.what)} | ${cell(i.usedFor)} | ${cell(i.author)} | '
        '${cell(i.link)} | ${cell(i.licence)} | $credit | $status | $files |',
      );
    }
    return b.toString();
  }

  /// The dialog's groups: the known items that have a line, under their
  /// headings, in the order the record gives them.
  static List<CreditGroup> get groups {
    final order = <String>[];
    final lines = <String, List<String>>{};
    for (final item in items) {
      final heading = item.heading;
      final line = item.line;
      if (heading == null || line == null) continue;
      if (item.status != CreditStatus.known) continue;
      if (!lines.containsKey(heading)) order.add(heading);
      (lines[heading] ??= <String>[]).add(line);
    }
    return <CreditGroup>[
      for (final h in order) CreditGroup(heading: h, items: lines[h]!),
    ];
  }
}
