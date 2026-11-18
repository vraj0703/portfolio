import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:portfolio/data/di/dependency_manager.dart';
import 'package:portfolio/domain/analytics/analytics.dart';
import 'package:portfolio/domain/audio/app_audio.dart';
import 'package:portfolio/domain/config/logo_config.dart';
import 'package:portfolio/domain/config/title_chrome.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/domain/style/strings.dart';
import 'package:portfolio/presentation/bloc/menu_drawer_cubit.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';

/// The title screen's controls, across the top from the parked mark: the
/// sound switch, the way to the contact screen, and the drawer.
///
/// Shown on the two stages with no other way out ([SceneState.showsMenu]).
/// The logo screen offers "TAP TO ENTER" and nothing else on purpose, the
/// corridor has its signs cut into the walls, and the contact screen *is* a
/// menu.
///
/// The sound switch and the way to the contact screen used to be rows at the
/// foot of the drawer, one press deeper than they needed to be. They are the
/// two things a visitor on this screen actually wants, so they sit beside the
/// control that used to hide them.
///
/// Placed from the mark rather than from numbers of its own — same inset from
/// its corner, same top edge — so the mark and the row hold the top of the
/// screen between them at every viewport. Read left to right, which is also
/// the focus order: sound, connect, menu, with the menu last because it is the
/// one that opens something else.
class TitleActions extends StatelessWidget {
  const TitleActions({super.key});

  /// Smallest square that can be pressed, whatever the glyph measures.
  ///
  /// What is drawn and what is pressed are allowed to differ; the target
  /// grows outward from the glyph, so the drawing stays on the line the mark
  /// sets regardless of how large the target has to be. Above the 44 a touch
  /// target needs, and the three side by side still take under a third of a
  /// phone's width.
  static const double minTarget = 48;

  /// How large a control is drawn, against the mark it hangs opposite.
  ///
  /// A fraction, not a match. Drawn at the mark's full height the two were
  /// the same size, and that is the wrong relationship: the mark is who the
  /// site belongs to and these are ways to do something. Reading them as
  /// equals made the corner look like it carried two logos.
  ///
  /// Bounded at both ends because the mark is not: it stands 79 tall on a
  /// desktop and 19 on a phone, so a bare fraction gives either a slab or
  /// something too small to find.
  static const double markRatio = 0.4;
  static const double minMark = 20;
  static const double maxMark = 32;

  /// The gap between two controls, against the glyph they draw.
  ///
  /// Each target already overhangs its glyph, but on a desktop, where the
  /// glyph nearly fills the 48 target, three of them side by side read as one
  /// strip. A share of the glyph keeps the gap in proportion at every size.
  static const double gapRatio = 0.5;

  /// How tall the parked mark stands, which is the line these hang from.
  static double markHeightFor(Size viewport) =>
      LogoConfig.logoMarkWidthFor(
        viewportWidth: viewport.width,
        viewportHeight: viewport.height,
      ) *
      LogoConfig.markAspect *
      LogoConfig.exitScale;

  /// How tall each glyph is drawn, for the same viewport.
  static double glyphHeightFor(Size viewport) =>
      (markHeightFor(viewport) * markRatio).clamp(minMark, maxMark);

  /// The row's sizes and place on a screen of [viewport] with system
  /// [insets]. A compact screen (a phone) follows Material through
  /// [TitleChrome]: 24 dp glyphs in 48 dp targets, the targets' edge 16 dp in
  /// and clear of the insets. A wider screen keeps the desktop rule: glyphs
  /// from the parked mark, the last *glyph* (not its target) on the mark's
  /// margin.
  static ActionRowLayout rowFor(Size viewport, EdgeInsets insets) {
    if (TitleChrome.isCompact(viewport)) {
      return ActionRowLayout(
        glyph: TitleChrome.icon,
        target: TitleChrome.target,
        spacing: TitleChrome.gap,
        top: insets.top + TitleChrome.edge,
        right: insets.right + TitleChrome.edge,
      );
    }
    final glyph = glyphHeightFor(viewport);
    final target = math.max(minTarget, glyph);
    // How far a target overhangs its glyph on each side.
    final overhang = (target - glyph) / 2;
    return ActionRowLayout(
      glyph: glyph,
      target: target,
      spacing: glyph * gapRatio,
      top: LogoConfig.exitMargin - overhang,
      right: LogoConfig.exitMargin - overhang,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SceneBloc, SceneState>(
      buildWhen: (previous, current) =>
          previous.showsMenu != current.showsMenu ||
          previous.showsMenuButton != current.showsMenuButton,
      builder: (context, state) {
        if (!state.showsMenu) return const SizedBox.shrink();

        final row = rowFor(
          MediaQuery.sizeOf(context),
          MediaQuery.paddingOf(context),
        );
        final glyph = row.glyph;
        final target = row.target;

        return Positioned(
          top: row.top,
          right: row.right,
          child: FocusTraversalGroup(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: row.spacing,
              children: <Widget>[
                TitleActionEntry(
                  order: 0,
                  child: SoundButton(glyph: glyph, target: target),
                ),
                // Behind its feature flag, read from the state (see
                // [SceneState.showsMenuButton]): a flag is a rule on the
                // state, not a branch here. The heart that stood between
                // them went to the drawer's bar (PORTFOLIO-23).
                if (state.showsMenuButton)
                  TitleActionEntry(
                    order: 1,
                    child: MenuButton(glyph: glyph, target: target),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// One control's way onto the screen: it rises a little, overshoots, and
/// settles, [stagger] after the one before it, so the row arrives as a wave
/// rather than all at once.
///
/// Implicit, so it stays stateless: a [TweenAnimationBuilder] runs once when
/// the row is first built, which is when the title shows it
/// ([SceneState.showsMenu]). The delay is an [Interval] inside each tween
/// rather than a timer, so nothing outlives the widget. A visitor who asked
/// for less motion gets the row already at rest.
class TitleActionEntry extends StatelessWidget {
  const TitleActionEntry({super.key, required this.order, required this.child});

  /// How long after the one before it each control sets off.
  static const Duration stagger = Duration(milliseconds: 100);

  /// How long one control takes to rise and settle.
  static const Duration rise = Duration(milliseconds: 420);

  /// How far below its place a control starts, in logical pixels. Small: a
  /// rise and settle, not a fly-in.
  static const double lift = 10;

  /// Place in the wave, from the left.
  final int order;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final delay = stagger * order;
    final total = delay + rise;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: still ? 1 : 0, end: 1),
      duration: still ? Duration.zero : total,
      curve: Interval(delay.inMicroseconds / total.inMicroseconds, 1),
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        // Announced from the first frame: a screen reader has no use for the
        // fade, and a control it cannot find for half a second is missing.
        alwaysIncludeSemantics: true,
        // `easeOutBack` passes its target and comes back: the small rise
        // above its place before it settles.
        child: Transform.translate(
          offset: Offset(0, (1 - Curves.easeOutBack.transform(t)) * lift),
          child: child,
        ),
      ),
    );
  }
}

/// Turns every sound in the site off, and on again.
///
/// The mark and the label both say what pressing will do, never what the
/// switch currently is: silent, it offers to turn the sound on and shows a
/// speaker; sounding, it offers to turn it off and shows the mute.
class SoundButton extends StatelessWidget {
  const SoundButton({super.key, required this.glyph, required this.target});

  static const String speaker = 'assets/vectors/speaker.svg';
  static const String mute = 'assets/vectors/mute.svg';

  final double glyph;
  final double target;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SceneBloc, SceneState, bool>(
      selector: (state) => state.muted,
      builder: (context, muted) {
        final colors = context.colors;
        final strings = context.strings;

        return _ActionIcon(
          icon: muted ? speaker : mute,
          label: muted ? strings.menuSoundOn : strings.menuSoundOff,
          tint: muted ? colors.menuTextSoft : colors.menuMark,
          glyph: glyph,
          target: target,
          onTap: () =>
              context.read<SceneBloc>().add(const SceneEvent.muteToggled()),
        );
      },
    );
  }
}

/// The control that opens the drawer.
class MenuButton extends StatelessWidget {
  const MenuButton({super.key, required this.glyph, required this.target});

  static const String icon = 'assets/vectors/menu.svg';

  final double glyph;
  final double target;

  @override
  Widget build(BuildContext context) {
    return _ActionIcon(
      icon: icon,
      label: context.strings.menuOpen,
      tint: context.colors.menuMark,
      glyph: glyph,
      target: target,
      onTap: () {
        // A step further in, answered by `previous` on the way out.
        context.audio.play(AudioCue.next);
        context.read<MenuDrawerCubit>().open();
        locate<SiteEvents>().menuOpened();
      },
    );
  }
}

/// One pressable mark: a glyph centred in a target at least as large.
///
/// An [InkResponse] rather than a bare [GestureDetector], because a
/// [GestureDetector] cannot take focus — a keyboard visitor would tab straight
/// past the row. This one takes focus, shows it, and answers Enter and Space.
class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.label,
    required this.tint,
    required this.glyph,
    required this.target,
    required this.onTap,
  });

  final String icon;
  final String label;
  final Color tint;
  final double glyph;
  final double target;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // The same icons in both scenes; the ink is the scene's to decide.
    final onLight = context.select<SceneBloc, bool>(
      (bloc) => bloc.state.chromeOnLight,
    );
    final ink = onLight ? colors.galleryChromeInk : tint;

    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: target / 2,
        focusColor: colors.menuEdge,
        hoverColor: colors.menuEdge.withValues(alpha: 0.12),
        highlightColor: colors.menuEdge.withValues(alpha: 0.2),
        splashColor: colors.menuEdge.withValues(alpha: 0.2),
        child: SizedBox(
          width: target,
          height: target,
          child: Center(
            child: SvgPicture.asset(
              icon,
              height: glyph,
              // Drawn in its own black, like every other mark here, and
              // tinted on the way in — one file serves wherever it is used,
              // and the colour stays the theme's to decide.
              colorFilter: ColorFilter.mode(ink, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }
}

/// Where the title's action row sits and how big its parts are.
class ActionRowLayout {
  const ActionRowLayout({
    required this.glyph,
    required this.target,
    required this.spacing,
    required this.top,
    required this.right,
  });

  final double glyph;
  final double target;
  final double spacing;
  final double top;
  final double right;
}
