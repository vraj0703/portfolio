import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:portfolio/core/di/dependency_manager.dart';
import 'package:portfolio/domain/audio/app_audio.dart';
import 'package:portfolio/domain/config/logo_config.dart';
import 'package:portfolio/domain/contact/contact_links.dart';
import 'package:portfolio/domain/contact/contact_menu.dart';
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

  /// How long the screen takes to come up out of the dark.
  ///
  /// The other half of the corridor going out — see `GalleryView.leaving`.
  /// Between them the two renderers hand over through black rather than
  /// cutting, which is the only way they can: they are separate engines and
  /// there is no frame in which both are drawing.
  ///
  /// Longer than the going-out, because a room being revealed reads slower
  /// than a room being left.
  static const Duration arrival = Duration(milliseconds: 620);

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

class _ContactMenu extends StatelessWidget {
  const _ContactMenu();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final width = MediaQuery.sizeOf(context).width;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        TweenAnimationBuilder<double>(
          // Fades up with the lines rather than appearing over them. Implicit
          // rather than driven: the layer mounts when the state arrives and
          // is gone when it leaves, so there is no reverse to run and nothing
          // to hold a controller for.
          tween: Tween<double>(begin: 0, end: 1),
          duration: LogoConfig.entranceDuration,
          curve: Curves.easeOut,
          builder: (context, entrance, child) =>
              Opacity(opacity: entrance, child: child),
          child: Align(
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
                child: const _MenuRow(),
              ),
            ),
          ),
        ),

        // The dark the corridor went out through, lifting off everything at
        // once — the ground, the mark and the menu together. Above the menu
        // rather than under it, so the screen is revealed as one thing
        // instead of a row of words already lit on a black field.
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 1, end: 0),
          duration: ContactMenuLayer.arrival,
          curve: Curves.easeOut,
          builder: (context, veil, _) => veil <= 0.001
              // Gone entirely once it has lifted, rather than a transparent
              // sheet left lying over the menu swallowing taps.
              ? const SizedBox.shrink()
              : IgnorePointer(
                  child: ColoredBox(
                    color: colors.sceneVeil.withValues(alpha: veil),
                  ),
                ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow();

  @override
  Widget build(BuildContext context) {
    const entries = ContactMenu.entries;

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
            if (i > 0) const _Separator(),
            _MenuItem(entry: entries[i]),
          ],
        ],
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

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
  const _MenuItem({required this.entry});

  final ContactEntry entry;

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
                    wordFor(strings, destination),
                    style: context.typography.contactMenu.copyWith(
                      color: colour,
                    ),
                  ),
                if (widget.entry.isMark) ...<Widget>[
                  if (widget.entry.hasWords) const SizedBox(width: 6),
                  SvgPicture.asset(
                    widget.entry.icon!,
                    height: widget.entry.hasWords
                        ? _MenuItem.markSize
                        : _MenuItem.doorwayMarkSize,
                    // The marks are drawn in their own dark ink; without
                    // this they arrive as near-black shapes on a near-black
                    // ground.
                    colorFilter: ColorFilter.mode(colour, BlendMode.srcIn),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

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
