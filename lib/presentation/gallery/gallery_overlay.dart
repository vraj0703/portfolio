import 'package:flutter/material.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';
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

  static const Color ink = Color(0xFFF0E4CC);
  static const Color plate = Color(0xCC1A1512);

  @override
  Widget build(BuildContext context) {
    final isFocused = focused != null;

    return Stack(
      children: <Widget>[
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
              color: GalleryOverlay.plate,
              shape: BoxShape.circle,
              border: Border.all(
                color: GalleryOverlay.ink.withValues(alpha: 0.45),
              ),
            ),
            alignment: Alignment.center,
            child: Text(glyph, style: context.typography.galleryControl),
          ),
        ),
      ),
    );
  }
}
