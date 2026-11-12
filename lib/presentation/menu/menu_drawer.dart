import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:portfolio/domain/audio/app_audio.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/domain/style/strings.dart';
import 'package:portfolio/domain/style/text_styles.dart';
import 'package:portfolio/presentation/bloc/menu_drawer_cubit.dart';

/// The panel the title screen's control opens.
///
/// Slides in from the right over a scrim, and closes on the scrim, on its own
/// control, or on Escape. The project list the previous site kept in here is
/// deferred, and the two things it used to hold — the sound switch and the
/// way to the contact screen — sit beside the control that opens it now, so
/// for the moment it holds only its own way out.
class MenuDrawer extends StatelessWidget {
  const MenuDrawer({super.key});

  /// How wide the panel is, and where it stops being a panel and becomes the
  /// whole screen. Both carried over from the previous site.
  static const double width = 320;
  static const double mobileBreakpoint = 600;

  static const Duration enter = Duration(milliseconds: 240);
  static const Duration exit = Duration(milliseconds: 180);

  /// What the panel does to the scene behind it, carried over from the
  /// previous site: a heavy blur under a mostly-opaque ground, rather than a
  /// solid sheet. The room stays visible as a suggestion of itself, which is
  /// what stops the panel reading as a different page.
  static const double blur = 12;
  static const double panelOpacity = 0.85;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MenuDrawerCubit, bool>(
      builder: (context, isOpen) {
        // `Positioned.fill` in both branches, never `SizedBox.shrink`.
        //
        // This is one child of a stack that positions others. A
        // non-positioned child of zero size collapses that stack under
        // `Clip.hardEdge`, taking the menu control and the arrow off screen
        // with it — a bug the previous site spent a ticket finding.
        if (!isOpen) {
          return const Positioned.fill(
            child: IgnorePointer(child: SizedBox.shrink()),
          );
        }

        return const Positioned.fill(child: _OpenDrawer());
      },
    );
  }
}

/// Stateful because the panel has to animate *out* before it leaves the tree.
/// A close that takes it off immediately is the panel vanishing rather than
/// leaving.
class _OpenDrawer extends StatefulWidget {
  const _OpenDrawer();

  @override
  State<_OpenDrawer> createState() => _OpenDrawerState();
}

class _OpenDrawerState extends State<_OpenDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: MenuDrawer.enter,
    reverseDuration: MenuDrawer.exit,
  )..forward();

  final FocusNode _keys = FocusNode()..requestFocus();

  bool _closing = false;

  @override
  void dispose() {
    _slide.dispose();
    _keys.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    // Guarded: the scrim, the close control and Escape all reach here, and a
    // second press mid-exit would run the animation back from wherever it had
    // got to.
    if (_closing) return;
    _closing = true;

    // Answers the step `next` took to open it.
    context.audio.play(AudioCue.previous);
    await _slide.reverse();
    if (mounted) context.read<MenuDrawerCubit>().dismiss();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context).width;
    final panel = screen < MenuDrawer.mobileBreakpoint
        ? screen
        : MenuDrawer.width;

    final scrim = context.colors.menuScrim;

    return KeyboardListener(
      focusNode: _keys,
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          unawaited(_close());
        }
      },
      child: AnimatedBuilder(
        animation: _slide,
        builder: (context, _) {
          final t = Curves.easeOutCubic.transform(_slide.value);

          return Stack(
            children: <Widget>[
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => unawaited(_close()),
                  child: ColoredBox(
                    color: scrim.withValues(alpha: scrim.a * t),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: panel,
                child: Transform.translate(
                  offset: Offset(panel * (1 - t), 0),
                  child: _Panel(onClose: _close),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.onClose});

  final Future<void> Function() onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: MenuDrawer.blur,
          sigmaY: MenuDrawer.blur,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.menuPanel.withValues(
              alpha: MenuDrawer.panelOpacity,
            ),
            border: Border(left: BorderSide(color: colors.menuEdge)),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _CloseRow(onClose: onClose),

                // Where the projects and the writing will go. Empty on
                // purpose: the sound switch and the way to the contact screen
                // used to sit at the foot of it, and they moved up beside the
                // control that opens it (`TitleActions`).
                const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The way out, as a word.
///
/// A word rather than a glyph, and right-aligned above the panel's contents,
/// which is how the credits dialog already says the same thing. The previous
/// site put "MENU" beside a cross here; the heading labelled a panel the
/// visitor had just opened deliberately, and the cross was the one control on
/// this screen that was not a word.
class _CloseRow extends StatelessWidget {
  const _CloseRow({required this.onClose});

  final Future<void> Function() onClose;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        // Clear of both edges. Pressed into the corner it read as part of
        // the frame rather than something to press, and on a phone it sat
        // where the system's own furniture does.
        padding: const EdgeInsets.only(right: 16, top: 16),
        child: TextButton(
          onPressed: () => unawaited(onClose()),
          child: Text(
            context.strings.menuClose,
            style: context.typography.menuAction.copyWith(
              color: context.colors.menuTextSoft,
            ),
          ),
        ),
      ),
    );
  }
}
