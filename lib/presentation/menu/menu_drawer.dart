import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:portfolio/data/di/dependency_manager.dart';
import 'package:portfolio/domain/audio/app_audio.dart';
import 'package:portfolio/domain/radio/radio_player.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/domain/style/strings.dart';
import 'package:portfolio/domain/style/text_styles.dart';
import 'package:portfolio/presentation/bloc/menu_drawer_cubit.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';

/// The panel the title screen's control opens.
///
/// Slides in from the right over a scrim, and closes on the scrim, on its own
/// control, or on Escape. The project list the previous site kept in here is
/// deferred; what it holds now is the two things a visitor on the title
/// screen has no other way to reach — the sound switch and the way to the
/// contact screen.
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
                // purpose, and it takes the space so the two controls below
                // sit at the foot of the panel rather than floating under
                // the way out.
                const Expanded(child: SizedBox.shrink()),

                const _SoundSwitch(),
                _ConnectRow(onClose: onClose),
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

/// Turns every sound in the site off, and on again.
///
/// Both of them. The scene's cues and the wall radio are separate players,
/// and a switch that silenced one while the other played on would not be a
/// mute — it would be a volume control the visitor could not find.
class _SoundSwitch extends StatefulWidget {
  const _SoundSwitch();

  @override
  State<_SoundSwitch> createState() => _SoundSwitchState();
}

class _SoundSwitchState extends State<_SoundSwitch> {
  static const String speaker = 'assets/vectors/speaker.svg';
  static const String mute = 'assets/vectors/mute.svg';

  void _toggle() {
    final audio = context.audio;
    final silencing = !audio.isMuted;

    // The confirmation plays before the silence, and not at all on the way
    // into it — a click swallowed by the thing it is confirming leaves the
    // press feeling unregistered.
    if (!silencing) audio.play(AudioCue.click);

    audio.setMuted(silencing);
    unawaited(
      locate<RadioPlayer>().setVolume(
        silencing ? 0 : RadioState.defaultVolume,
      ),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final muted = context.audio.isMuted;

    // Both the mark and the word say what pressing will do, never what the
    // switch currently is: silent, this offers to turn the sound on and
    // shows a speaker; sounding, it offers to turn it off and shows the
    // mute. A row in a list is something to choose, and one labelled with
    // its own state reads as a description until somebody presses it.
    return _MenuRow(
      icon: muted ? speaker : mute,
      label: muted ? strings.menuSoundOn : strings.menuSoundOff,
      tint: muted ? colors.menuTextSoft : colors.menuMark,
      onTap: _toggle,
    );
  }
}

class _ConnectRow extends StatelessWidget {
  const _ConnectRow({required this.onClose});

  final Future<void> Function() onClose;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SceneBloc>();
    final audio = context.audio;

    return _MenuRow(
      icon: 'assets/vectors/heart.svg',
      label: context.strings.menuConnect,
      tint: context.colors.menuMark,
      leading: true,
      onTap: () async {
        // Closed first, then the scene moves. The contact screen is the logo
        // composition and the mark travels into the middle of it; a panel
        // still sliding off the right while that happens is two animations
        // arguing over one screen.
        audio.play(AudioCue.pageTurn);
        await onClose();
        bloc.queue(event: const SceneEvent.contactRequested());
      },
    );
  }
}

/// One pressable row: a mark, a word, and the panel's whole width to hit.
class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.tint,
    required this.onTap,
    this.leading = false,
  });

  final String icon;
  final String label;
  final Color tint;

  /// Whether this row opens the group, and so carries the heavier rule above.
  final bool leading;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: colors.menuEdge.withValues(
                  alpha: leading ? 0.15 : 0.08,
                ),
              ),
            ),
          ),
          child: Row(
            children: <Widget>[
              SvgPicture.asset(
                icon,
                height: 20,
                colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
              ),
              const SizedBox(width: 16),

              // Given the rest of the row rather than its natural width. At
              // 20pt in a 320 panel a label has little room to spare, and a
              // `Row` hands an unbounded child exactly what it asks for and
              // then overflows — so the one thing that can yield has to be
              // told that it may.
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.typography.menuEntry.copyWith(
                    color: colors.menuText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
