import 'dart:ui';

import 'piece_art.dart';

/// The corridor's seven frames. The left wall is what Vishal builds now; the
/// right wall is where he built before.
///
/// Every number and claim here can be checked: Shunya Systems against the
/// mantr, yantr and infra repositories, tantr against the tantr-app
/// repository and https://tantr.app, Twin Health and FieldAssist / PayU
/// against the entries this list replaced and the old static page. Anything
/// not yet backed by a fact is left out of what renders and marked with a
/// `TODO(vishal)` comment beside it. A TODO marker never reaches the wall or
/// the static page; the frames still waiting on facts are `soon`, which show
/// their title and nothing they cannot back.
///
/// Ordering is load-bearing. [GalleryProjects.left] and
/// [GalleryProjects.right] index into [GalleryProjects.all] to build the
/// paired corridor layout, and the corridor's physical length is derived
/// from the left-wall count in `gallery_dimensions.dart`. Reordering this
/// list moves walls.

/// How far along a piece of work is.
///
/// A gallery does not hang an empty frame where a work is not ready — it
/// hangs the frame and says so on the card. Unfinished work stays on the wall
/// because the shape of what is coming is itself worth seeing; it is simply
/// not lit the same way. See `GalleryLighting`, where [ProjectStatus.soon]
/// gets a dimmer picture light: the room states the difference before any
/// text does.
enum ProjectStatus {
  /// Finished, public, and worth reading in full.
  live,

  /// Announced, not yet ready. Shows its premise and nothing it cannot back.
  soon,
}

class Project {
  const Project({
    required this.id,
    required this.title,
    required this.line,
    required this.url,
    required this.accent,
    required this.art,
    this.figure = '',
    this.tags = const <String>[],
    this.years = '',
    this.stats = const <String>[],
    this.status = ProjectStatus.live,
    this.summary = '',
    this.stack = const <String>[],
  });

  final String id;

  /// The name, on the wall label and at the head of the sheet. One to three
  /// words.
  final String title;

  /// What it is, in at most eight words: the wall label's second line.
  final String line;

  /// The one number that proves it, on the wall label. Empty when there is
  /// none yet, and then left off the label rather than announced.
  final String figure;

  /// The tools, no more than three, on the wall label. Empty until they are
  /// known; the label leaves the row out.
  final List<String> tags;

  /// When, on the wall label. Empty until known, and left off.
  final String years;

  final String url;

  /// The one colour in the drawing; everything else is ink on paper.
  final Color accent;

  /// The drawing made from the project's own facts; see [PieceDrawing].
  final PieceArt art;

  /// The case's three numbers, on the sheet.
  final List<String> stats;

  final ProjectStatus status;

  /// What the work is for, in the visitor's terms rather than the author's.
  ///
  /// Read on the sheet, at arm's length, by someone who has already stopped,
  /// and answers the question a label cannot: *why does this exist*.
  final String summary;

  /// What it is built with, on the sheet. Named, not counted: a stack is how
  /// a reader decides whether they recognise the work, and a number tells
  /// them nothing.
  final List<String> stack;

  /// Whether there is a finished case to read, as opposed to a premise.
  bool get isLive => status == ProjectStatus.live;

  /// Projects with no public link render without a clickable affordance.
  bool get hasLink => url.isNotEmpty && url != '#';
}

abstract final class GalleryProjects {
  static const List<Project> all = <Project>[
    // 0 · left 1 — what he builds now.
    Project(
      id: 'shunya-systems',
      title: 'Shunya Systems',
      line: 'A two-person company run with AI agents',
      figure: '22 written rules',
      tags: <String>['Claude Code', 'Python', 'Salt'],
      years: '2026',
      // TODO(vishal): the repositories are private; link a public page here
      // or leave it without one.
      url: '#',
      accent: Color(0xFFC1900A),
      art: PieceArt.mesh,
      stats: <String>['5 nodes', '22 written rules', '15 instruments'],
      summary:
          'A company of two, Vishal and an AI chief of staff. The agent '
          'plans and reviews on one machine and hands the work to agents on '
          'the others, under 22 written rules that say what it may do alone, '
          'what it must ask about, and what it must never touch.',
      stack: <String>['Claude Code', 'Python', 'Salt', 'Tailscale'],
    ),
    // 1 · right 1 — where he built before.
    Project(
      id: 'twin-health',
      title: 'Twin Health',
      line: 'Digital health platform',
      figure: '67 releases, 0 hotfixes',
      // TODO(vishal): the label's three tags.
      years: '2022 –',
      url: '#',
      accent: Color(0xFF5B5FE0),
      art: PieceArt.tally,
      stats: <String>['67 releases', '0 hotfixes', r'$87K saved'],
      summary:
          'A digital health platform, from 2022: 67 releases shipped '
          'without a single hotfix.',
      // TODO(vishal): the role, what the $87K saving was, and the stack.
    ),
    // 2 · left 2
    Project(
      id: 'tantr',
      title: 'tantr app',
      line: 'One runtime for what every app rebuilds',
      figure: '31 packages',
      tags: <String>['Flutter', 'Dart', 'JSON Schema'],
      years: '2026',
      url: 'https://tantr.app',
      accent: Color(0xFF0F9F73),
      art: PieceArt.nested,
      stats: <String>['31 packages', '5 profiles', '7 apps'],
      summary:
          'Most product apps rebuild the same five things: forms, insight '
          'cards, notifications, asking the user to act, and chat. tantr '
          'writes them once behind one wire contract, and a new product is '
          'carved from a reference app in one command.',
      stack: <String>['Flutter', 'Dart', 'shelf', 'JSON Schema'],
    ),
    // 3 · right 2
    Project(
      id: 'fieldassist-payu',
      title: 'FieldAssist / PayU',
      line: 'Field force at scale, payment encryption',
      figure: '1,600+ files',
      // TODO(vishal): the label's three tags.
      years: '2016 –',
      url: '#',
      accent: Color(0xFFB07D28),
      art: PieceArt.field,
      stats: <String>['1,600+ files', 'Multi-flavor', 'Triple DES'],
      summary:
          'At PayU, in fintech from 2016: client-side encryption of card PIN '
          'and PAN with Triple DES. At FieldAssist, in FMCG from 2018: an '
          'enterprise field-force app of more than 1,600 files, shipped in '
          'several flavors.',
      // TODO(vishal): the role at each, and the stack.
    ),
    // 4 · left 3
    Project(
      id: 'publications',
      title: 'Publications',
      line: 'Open-source packages and one Play Store app',
      figure: '12 published',
      tags: <String>['Node', 'Python', 'Flutter'],
      // TODO(vishal): the years.
      url: 'https://www.npmjs.com/~vraj0703',
      accent: Color(0xFF4A40C8),
      art: PieceArt.constellation,
      stats: <String>['6 npm packages', '5 PyPI projects', '1 Play Store app'],
      summary:
          'The parts of the agent systems, published for anyone to install: '
          'six npm packages under @raj-sadan (mind, memory, knowledge, '
          'senses, a dashboard and a utility library) and five Python '
          'projects on PyPI, among them ai-constitution. Jotter, a notes '
          'app, is on Google Play.',
      stack: <String>['Node', 'Python', 'Flutter'],
    ),
    // 5 · right 3
    Project(
      id: 'school-college',
      title: 'School and College',
      // TODO(vishal): the schools, the college, the degree and the years.
      line: 'In preparation',
      url: '#',
      accent: Color(0xFFD98A0A),
      art: PieceArt.rings,
      status: ProjectStatus.soon,
      // TODO(vishal): two or three sentences on where it started.
    ),
    // 6 · left 4, alone past the end of the right wall
    Project(
      id: 'creative-works',
      title: 'Creative Works',
      // TODO(vishal): which works, and a link.
      line: 'In preparation',
      url: '#',
      accent: Color(0xFFD94A3A),
      art: PieceArt.brush,
      status: ProjectStatus.soon,
      // TODO(vishal): two or three sentences on the creative work.
    ),
  ];

  /// Left wall, what he builds now: indices 0, 2, 4, 6. Takes the extra
  /// frame — the last hangs alone past the point where the right wall stops
  /// and opens into the L.
  static final List<Project> left = <Project>[all[0], all[2], all[4], all[6]];

  /// Right wall, where he built before: indices 1, 3, 5. Each faces its
  /// left-wall pair.
  static final List<Project> right = <Project>[all[1], all[3], all[5]];
}
