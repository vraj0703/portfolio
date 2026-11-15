import 'package:flutter/material.dart';
import 'package:portfolio/domain/gallery/project_data.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';
import 'package:portfolio/domain/style/strings.dart';
import 'package:portfolio/domain/style/text_styles.dart';

/// The gallery's controls, drawn over the room.
///
/// Over rather than in, after trying it the other way. Mounting these on the
/// walls as `WidgetComponent` surfaces was the more elegant idea — controls
/// lit by the room's own lights, turning with the wall it hangs on — but the
/// component rasterises on its update policy whether or not its node is
/// visible, so three hidden surfaces re-recorded inside the render loop on
/// every frame of the walk. That is what made the corridor stutter.
///
/// These are chrome, not content: they are the visitor's controls, not part
/// of the work on display, and they have to stay reachable whatever the
/// camera is doing. Drawing them here costs nothing when nothing changes.
class GalleryOverlay extends StatelessWidget {
  const GalleryOverlay({
    required this.focused,
    required this.canGoBack,
    required this.canGoForward,
    required this.onBack,
    required this.onExit,
    required this.onForward,
    required this.mirrored,
    required this.asFallback,
    this.reading = false,
    this.onRead,
    this.onCloseSheet,
    this.onOpenProject,
    super.key,
  });

  /// The piece being read, or null while walking the corridor.
  final Placement? focused;

  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onBack;
  final VoidCallback onExit;
  final VoidCallback onForward;

  /// Whether the piece in view hangs on the right-hand wall.
  ///
  /// The camera reads that wall from the opposite side, so the corridor runs
  /// the other way across the screen: walking deeper in *appears* to move
  /// left. Leaving the row alone put the only live arrow on the wrong side of
  /// ✕ and pointed it away from where it would actually take you.
  final bool mirrored;

  /// Whether to draw the controls at all.
  ///
  /// False in the normal case: the controls are objects in the room, on the
  /// wall beneath the work. This row is what the visitor gets when those
  /// models cannot be read — a gallery whose navigation depends on a
  /// downloadable asset would be a gallery you could get stuck in.
  final bool asFallback;

  /// Whether the focused piece's case is open on the sheet.
  final bool reading;

  /// Opens the sheet; closes it back to the piece; opens the work itself,
  /// or null when the project has nowhere to go.
  final VoidCallback? onRead;
  final VoidCallback? onCloseSheet;
  final VoidCallback? onOpenProject;

  /// How long the sheet takes to come up or go down.
  static const Duration sheetTravel = Duration(milliseconds: 280);

  @override
  Widget build(BuildContext context) {
    final isFocused = focused != null;
    final project = focused?.project;
    final canRead = project != null && project.isLive && onRead != null;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final travel = still ? Duration.zero : sheetTravel;

    return Stack(
      children: <Widget>[
        // "Read the case": over the room, for a finished piece only, in the
        // corner on the label's side. Not under the piece: the room's own
        // three controls hang there, and centred it covered the arrow on.
        // Real text and a real button, not a texture; it is the way into
        // the words the wall no longer carries.
        if (canRead && !reading)
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 24, bottom: 28),
              child: _ReadCase(onTap: onRead!),
            ),
          ),

        // The shade over the room while the sheet is up; a press on it is
        // a press outside the sheet, and closes it.
        IgnorePointer(
          ignoring: !reading,
          child: AnimatedOpacity(
            opacity: reading ? 1 : 0,
            duration: travel,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onCloseSheet,
              child: ColoredBox(
                color: context.colors.sheetShade,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),

        Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedSwitcher(
            duration: travel,
            transitionBuilder: (child, animation) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
              child: child,
            ),
            child: reading && project != null && project.isLive
                ? CaseSheet(
                    key: ValueKey<String>(project.id),
                    project: project,
                    onBack: onCloseSheet ?? () {},
                    onOpen: onOpenProject,
                  )
                : const SizedBox.shrink(),
          ),
        ),

        // The controls are only meaningful with something focused, and are
        // gone rather than disabled when nothing is: a permanent bar of dead
        // buttons reads as a broken interface.
        if (isFocused && asFallback)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 44),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Hidden at the ends, but its space is kept. Removing the
                  // box outright would slide ✕ off centre and shift the other
                  // arrow, so the control under the pointer would become a
                  // different control between one piece and the next.
                  _Slot(
                    visible: mirrored ? canGoForward : canGoBack,
                    child: _Control(
                      glyph: '‹',
                      label: mirrored ? 'Next work' : 'Previous work',
                      onTap: mirrored ? onForward : onBack,
                    ),
                  ),
                  const SizedBox(width: 14),
                  _Control(
                    glyph: '✕',
                    label: 'Back to the corridor',
                    onTap: onExit,
                  ),
                  const SizedBox(width: 14),
                  _Slot(
                    visible: mirrored ? canGoBack : canGoForward,
                    child: _Control(
                      glyph: '›',
                      label: mirrored ? 'Previous work' : 'Next work',
                      onTap: mirrored ? onBack : onForward,
                    ),
                  ),
                ],
              ),
            ),
          ),

      ],
    );
  }
}

/// The control that opens the sheet.
class _ReadCase extends StatelessWidget {
  const _ReadCase({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            decoration: BoxDecoration(
              color: colors.sheetInk,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              context.strings.readTheCase,
              style: context.typography.readCase.copyWith(
                color: colors.sheetGround,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A piece's case, in real text over the room: the name, the summary, the
/// three numbers, the stack, the way out to the work, and the way back to
/// the piece.
///
/// Selectable and read by a screen reader, which a texture in the room
/// cannot be. Sized for a thumb on a phone: full width there, the buttons
/// at least 48 tall, and the words scroll if they outgrow the sheet.
class CaseSheet extends StatelessWidget {
  const CaseSheet({
    required this.project,
    required this.onBack,
    this.onOpen,
    super.key,
  });

  final Project project;
  final VoidCallback onBack;
  final VoidCallback? onOpen;

  /// How much of the screen the sheet may take before its words scroll.
  static const double maxHeightShare = 0.78;

  /// Its widest, on a large screen: a reading measure, not a banner.
  static const double maxWidth = 760;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.typography;
    final strings = context.strings;
    final height = MediaQuery.sizeOf(context).height;
    final ink = colors.sheetInk;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: strings.theCase,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: height * maxHeightShare,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.sheetGround,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 22),
              child: SelectionArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: colors.sheetGrip,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Text(
                      project.title,
                      style: type.sheetTitle.copyWith(color: ink),
                    ),
                    if (project.summary.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 10),
                      Text(
                        project.summary,
                        style: type.sheetBody.copyWith(color: ink),
                      ),
                    ],
                    if (project.stats.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 22,
                        runSpacing: 6,
                        children: <Widget>[
                          for (final stat in project.stats)
                            Text(stat, style: type.sheetStat.copyWith(color: ink)),
                        ],
                      ),
                    ],
                    if (project.stack.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: <Widget>[
                          for (final tag in project.stack)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: colors.labelTagEdge),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                tag,
                                style: type.sheetTag.copyWith(color: ink),
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        if (onOpen != null)
                          _SheetButton(
                            label: strings.openTheProject,
                            onPressed: onOpen!,
                            filled: true,
                          ),
                        _SheetButton(
                          label: strings.backToThePiece,
                          onPressed: onBack,
                          autofocus: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.autofocus = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ink = colors.sheetInk;
    final paper = colors.sheetGround;
    return TextButton(
      autofocus: autofocus,
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        backgroundColor: filled ? ink : ink.withValues(alpha: 0),
        foregroundColor: filled ? paper : ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: ink),
        ),
        textStyle: context.typography.sheetButton,
      ),
      child: Text(label),
    );
  }
}

/// Keeps a control's place in the row whether or not it is shown.
class _Slot extends StatelessWidget {
  const _Slot({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (visible) return child;
    // Not `Visibility`: the point is to hold the space, and an invisible box
    // must also stop taking taps aimed at nothing.
    return const SizedBox(width: _Control.size, height: _Control.size);
  }
}

class _Control extends StatelessWidget {
  const _Control({
    required this.glyph,
    required this.label,
    required this.onTap,
  });

  static const double size = 52;

  final String glyph;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: context.colors.galleryControlPlate,
              shape: BoxShape.circle,
              border: Border.all(color: context.colors.galleryControlEdge),
            ),
            alignment: Alignment.center,
            child: Text(glyph, style: context.typography.galleryControl),
          ),
        ),
      ),
    );
  }
}
