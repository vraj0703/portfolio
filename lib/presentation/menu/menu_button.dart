import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:portfolio/domain/audio/app_audio.dart';
import 'package:portfolio/domain/config/logo_config.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/presentation/bloc/menu_drawer_cubit.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';

/// The control that opens the drawer, across the top from the parked mark.
///
/// Shown on the two stages with no other way out. The logo screen offers
/// "TAP TO ENTER" and nothing else on purpose, the corridor has its signs cut
/// into the walls, and the contact screen *is* a menu.
///
/// Placed from the mark rather than from numbers of its own — same inset from
/// its corner, same top edge — so the pair hold the top of the screen between
/// them at every viewport. Fixed at 22 it read as a stray glyph and drifted
/// as the window changed, because only one of the two was following it.
///
/// Aligned with the mark, but not matched to it: see [markRatio]. The top
/// edges agree; the sizes deliberately do not.
class MenuButton extends StatelessWidget {
  const MenuButton({super.key});

  static const String icon = 'assets/vectors/menu.svg';

  /// Smallest square that can be pressed, whatever the glyph measures.
  ///
  /// What is drawn and what is pressed are allowed to differ; the target
  /// grows outward from the glyph, so the drawing stays on the line the mark
  /// sets regardless of how large the target has to be.
  static const double minTarget = 48;

  /// How large the control is drawn, against the mark it hangs opposite.
  ///
  /// A fraction, not a match. Drawn at the mark's full height the two were
  /// the same size, and that is the wrong relationship: the mark is who the
  /// site belongs to and the control is a way to open a panel. Reading them
  /// as equals made the corner look like it carried two logos.
  ///
  /// Bounded at both ends because the mark is not: it stands 79 tall on a
  /// desktop and 19 on a phone, so a bare fraction gives either a slab or
  /// something too small to find.
  static const double markRatio = 0.4;
  static const double minMark = 20;
  static const double maxMark = 32;

  /// How tall the parked mark stands, which is the line this hangs from.
  static double markHeightFor(Size viewport) =>
      LogoConfig.logoMarkWidthFor(
        viewportWidth: viewport.width,
        viewportHeight: viewport.height,
      ) *
      LogoConfig.markAspect *
      LogoConfig.exitScale;

  /// How tall this is drawn, for the same viewport.
  static double glyphHeightFor(Size viewport) =>
      (markHeightFor(viewport) * markRatio).clamp(minMark, maxMark);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SceneBloc, SceneState>(
      buildWhen: (previous, current) =>
          previous.showsMenu != current.showsMenu,
      builder: (context, state) {
        if (!state.showsMenu) return const SizedBox.shrink();

        final glyph = glyphHeightFor(MediaQuery.sizeOf(context));
        final target = math.max(minTarget, glyph);

        // How far the target overhangs the glyph on each side. Subtracted
        // from the inset so the *glyph* lands on the mark's own margin rather
        // than the box drawn around it.
        final overhang = (target - glyph) / 2;

        return Positioned(
          top: LogoConfig.exitMargin - overhang,
          right: LogoConfig.exitMargin - overhang,
          child: Semantics(
            button: true,
            label: 'Open menu',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                // A step further in, answered by `previous` on the way out.
                context.audio.play(AudioCue.next);
                context.read<MenuDrawerCubit>().open();
              },
              child: SizedBox(
                width: target,
                height: target,
                child: Center(
                  child: SvgPicture.asset(
                    icon,
                    height: glyph,
                    // Drawn in its own black, like every other mark here, and
                    // tinted on the way in — one file serves wherever it is
                    // used, and the colour stays the theme's to decide.
                    colorFilter: ColorFilter.mode(
                      context.colors.menuMark,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
