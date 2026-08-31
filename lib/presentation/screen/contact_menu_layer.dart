import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:portfolio/core/di/dependency_manager.dart';
import 'package:portfolio/domain/audio/app_audio.dart';
import 'package:portfolio/domain/config/logo_config.dart';
import 'package:portfolio/domain/contact/contact_links.dart';
import 'package:portfolio/domain/contact/contact_menu.dart';
import 'package:portfolio/domain/contact/contact_typing.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/domain/style/text_styles.dart';
import 'package:portfolio/domain/style/strings.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/screen/credits_dialog.dart';

/// The contact menu, standing where "TAP TO ENTER" stands.
///
/// A Flutter layer over the Flame scene rather than a component inside it,
/// and the split is on purpose: the *composition* is the logo screen's — the
/// mark, the ground, the two bouncy lines — and all of that is still drawn by
/// the game. What is new here is seven things that can be pressed, two of
/// which open a browser and one a dialog. Flame draws pictures well and hands
/// off links badly; this is the half that needs hit-testing, a cursor, and a
/// route.
///
/// The two halves agree on where they meet through [LogoConfig] alone — the
/// lines read [LogoConfig.contactGap] for how far apart to stand and this
/// reads the same function for how wide it may be, so the menu cannot grow
/// out through the lines flanking it.
class ContactMenuLayer extends StatelessWidget {
  const ContactMenuLayer({super.key});

  /// Height of the row, used to put its centre exactly where the affordance's
  /// centre is in the game underneath.
  static const double rowHeight = 52;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SceneBloc, SceneState>(
      buildWhen: (previous, current) =>
          (previous is Contact) != (current is Contact),
      builder: (context, state) {
        if (state is! Contact) return const SizedBox.shrink();
        return const _ContactMenu();
      },
    );
  }
}

class _ContactMenu extends StatefulWidget {
  const _ContactMenu();

  @override
  State<_ContactMenu> createState() => _ContactMenuState();
}

/// Stateful for one reason, and it is the reason the rule allows: something
/// has to make a sound at a moment that is not a rebuild.
///
/// The row does not start writing when this mounts — it waits for the mark
/// to finish travelling in from the hall — so the cue belongs a fixed time
/// after mounting, and `build` is not a place to fire one. Nothing else here
/// outlives a frame; the entrance is still an implicit tween.
class _ContactMenuState extends State<_ContactMenu> {
  Timer? _typing;

  @override
  void initState() {
    super.initState();

    // Exactly the wait the tween spends before `typedAt` returns anything,
    // so the first keystroke and the first letter land on the same frame.
    // The sound then runs 3600ms, which is what the writing takes.
    _typing = Timer(LogoConfig.contactMenuLead, () {
      if (mounted) context.audio.play(AudioCue.keyboardTyping);
    });
  }

  @override
  void dispose() {
    // The visitor can leave before the row has started. A cue fired into a
    // screen that is no longer there is a sound with nothing under it.
    _typing?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        TweenAnimationBuilder<double>(
          // The affordance this stands in for does not fade in, it types —
          // and so does this. The tween carries the layer's entrance and
          // `LogoConfig.typedAt` turns it into how much of the row has
          // arrived, which is the same rule the label reads, so the two are
          // one animation rather than two of the same length.
          //
          // Implicit rather than driven: the layer mounts when the state
          // arrives and is gone when it leaves, so there is no reverse to
          // run and nothing to hold a controller for.
          tween: Tween<double>(begin: 0, end: 1),
          duration: LogoConfig.contactMenuDuration,
          curve: Curves.linear,
          builder: (context, entrance, _) => Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(
                bottom:
                    LogoConfig.overlayBottomMargin -
                    ContactMenuLayer.rowHeight / 2,
              ),
              child: SizedBox(
                height: ContactMenuLayer.rowHeight,
                // Never wider than the gap the lines leave for it.
                width: LogoConfig.contactGap(width) * 2,
                child: _MenuRow(
                  typed: LogoConfig.typedAt(
                    entrance,
                    from: LogoConfig.contactMenuTextStart,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.typed});

  /// How much of the row has arrived, `0`..`1`.
  final double typed;

  /// What each entry costs the typing, in characters.
  ///
  /// A word costs its letters and a mark costs one beat, so the row types at
  /// an even pace rather than an even beat per item — "linkedin" takes four
  /// times as long as "cv", which is what typing means.
  List<int> weights(AppStrings strings) => <int>[
    for (final entry in ContactMenu.entries)
      _MenuItemState.weightOf(strings, entry),
  ];

  @override
  Widget build(BuildContext context) {
    const entries = ContactMenu.entries;
    final costs = weights(context.strings);

    return FittedBox(
      // Shrinks rather than wraps. Seven destinations on one line is the
      // shape of the thing — broken over two it stops reading as a menu and
      // starts reading as a list, and on a narrow phone that is the choice.
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        // Explicit, because the dot has to sit on the row's middle rather
        // than on the type's baseline — a bullet hung off a baseline reads
        // as a full stop between the words instead of a separator.
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          for (var i = 0; i < entries.length; i++) ...<Widget>[
            if (i > 0)
              _Separator(
                shown: ContactTyping.separatorAfter(
                  index: i - 1,
                  typed: typed,
                  weights: costs,
                ),
              ),
            _MenuItem(
              entry: entries[i],
              reveal: ContactTyping.revealOf(
                index: i,
                typed: typed,
                weights: costs,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator({required this.shown});

  /// Whether the entry to its left has finished arriving.
  final double shown;

  /// How wide the drawing is rendered.
  ///
  /// Twice the dot: the artwork is a circle spanning half its own viewBox,
  /// so half of what is drawn here is the margin around it. Asking for the
  /// dot's diameter directly would give a mark twice the size intended.
  static const double drawnSize = 10;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Opacity(
        opacity: shown,
        child: SvgPicture.asset(
          ContactMenu.separatorIcon,
          width: drawnSize,
          height: drawnSize,
          // Dimmer than what it separates, so it reads as punctuation and not
          // as an eighth thing to press.
          colorFilter: ColorFilter.mode(
            context.colors.contactSeparator,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

/// One destination on the menu.
///
/// Stateful, and this is the exception the rule allows for: hover is a fact
/// about the pointer that only this widget knows and only this widget shows.
/// It cannot be derived from the bloc — the scene has no business knowing
/// which word the cursor is over — and without it a row of small grey words
/// gives no sign it can be pressed at all.
class _MenuItem extends StatefulWidget {
  const _MenuItem({required this.entry, required this.reveal});

  final ContactEntry entry;

  /// How much of this entry has arrived, `0`..`1`.
  ///
  /// A word is cut to that fraction of its letters, the way the affordance's
  /// label is. A mark cannot arrive half-drawn, so it fades across its one
  /// beat instead.
  final double reveal;

  /// Height of a mark that finishes a sentence.
  ///
  /// Above the cap height of the words beside it, not level with it: a heart
  /// is wider than it is tall, so matching cap height leaves it reading
  /// smaller than the type it sits in.
  static const double markSize = 21;

  /// Height of a mark that stands on its own.
  ///
  /// Larger, because the two doorways have no words to be read with. A word
  /// carries meaning at any size it is legible at; a drawing has to be
  /// recognised first, and at the size of the type beside it the gallery and
  /// the house are shapes before they are either.
  static const double doorwayMarkSize = 27;

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final destination = widget.entry.destination;

    final colour = _hovered
        ? colors.contactMenuTextActive
        : colors.contactMenuText;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => _follow(context, destination),
        behavior: HitTestBehavior.opaque,
        child: Semantics(
          button: true,
          label: strings.contactMarkLabel(destination),
          // The label speaks for the whole entry, marks included. Without
          // this the words inside announce themselves separately and the
          // label is never read — so "Made with ♥" reaches a screen reader
          // as "Made with", and the heart, which is the half that carries
          // the meaning, is silent.
          excludeSemantics: true,
          child: Padding(
            // Padding, not margin: it is the tap target on a touch screen,
            // where there is no hover to find the word with first.
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (!widget.entry.isMark || widget.entry.hasWords)
                  Text(
                    _typedWord(strings, wordFor(strings, destination)),
                    style: context.typography.contactMenu.copyWith(
                      color: colour,
                    ),
                  ),
                if (widget.entry.isMark) ...<Widget>[
                  if (widget.entry.hasWords) const SizedBox(width: 6),
                  Opacity(
                    // The mark's own beat, not the entry's. "Made with" has
                    // to be written before the heart it is about arrives.
                    opacity: ContactTyping.markOf(
                      reveal: widget.reveal,
                      weight: weightOf(strings, widget.entry),
                    ),
                    child: SvgPicture.asset(
                      widget.entry.icon!,
                      height: widget.entry.hasWords
                          ? _MenuItem.markSize
                          : _MenuItem.doorwayMarkSize,
                      // The marks are drawn in their own dark ink; without
                      // this they arrive as near-black shapes on a near-black
                      // ground.
                      colorFilter: ColorFilter.mode(colour, BlendMode.srcIn),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The word cut to however much of it has typed on.
  String _typedWord(AppStrings strings, String word) => word.substring(
    0,
    ContactTyping.lettersOf(
      reveal: widget.reveal,
      weight: weightOf(strings, widget.entry),
      letters: word.length,
    ),
  );

  /// What an entry costs the row, in characters.
  ///
  /// One expression, read by the row that lays the weights out and by the
  /// entry that divides its own between its word and its mark. They were the
  /// same arithmetic written twice, which is how the heart came to be fading
  /// in across letters that were still arriving.
  static int weightOf(AppStrings strings, ContactEntry entry) =>
      (entry.isMark ? ContactTyping.markWeight : 0) +
      wordFor(strings, entry.destination).length;

  /// The word an entry reads as, or empty for the two that are only marks.
  static String wordFor(AppStrings strings, ContactDestination destination) =>
      switch (destination) {
        ContactDestination.cv => strings.contactCv,
        ContactDestination.email => strings.contactEmail,
        ContactDestination.github => strings.contactGithub,
        ContactDestination.linkedin => strings.contactLinkedIn,
        ContactDestination.credits => strings.madeWith,
        // The two doorways are marks and nothing else.
        ContactDestination.gallery || ContactDestination.home => '',
      };

  /// Follows one destination.
  ///
  /// The two kinds are kept apart deliberately: three of them are moves
  /// within the scene and belong to the bloc, and the rest leave the page and
  /// belong to [ContactLinks]. Neither knows about the other.
  void _follow(BuildContext context, ContactDestination destination) {
    final bloc = context.read<SceneBloc>();

    // Null for the two doorways, which the stage they open announces for
    // itself. The four that hand off to a browser especially need a sound:
    // the click is the only acknowledgement the visitor gets that the page
    // heard them at all.
    final cue = ContactMenu.cueFor(destination);
    if (cue != null) context.audio.play(cue);

    switch (destination) {
      case ContactDestination.gallery:
        bloc.add(const SceneEvent.galleryRequested());
      case ContactDestination.home:
        bloc.add(const SceneEvent.homeRequested());
      case ContactDestination.credits:
        showCreditsDialog(context);
      case ContactDestination.cv:
        locate<ContactLinks>().downloadCv();
      case ContactDestination.email:
        locate<ContactLinks>().composeEmail();
      case ContactDestination.github:
        locate<ContactLinks>().openGithub();
      case ContactDestination.linkedin:
        locate<ContactLinks>().openLinkedIn();
    }
  }
}
