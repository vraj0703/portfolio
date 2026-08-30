import 'package:flutter/material.dart';
import 'package:portfolio/domain/config/mark_travel.dart';
import 'package:portfolio/domain/style/scene_palette.dart';

/// The header mark, in the corridor.
///
/// The same mark the title screen parked in its corner, still parked. The
/// corridor is drawn by a different renderer, so this is a second drawing of
/// it rather than the same object — but it reads from [MarkTravel] like the
/// first one, which is what keeps the two from disagreeing about where the
/// corner is.
///
/// It is also the thing that carries the visitor out. Pressing the invitation
/// in the skills hall sends [journey] from 1 back to 0, and the mark flies
/// out of the corner into the middle of the screen while the room goes dark
/// behind it — arriving exactly where the contact screen's own mark begins.
/// The renderers change underneath; the mark does not move.
class GalleryMark extends StatelessWidget {
  const GalleryMark({required this.journey, super.key});

  /// `1` parked in the corner, `0` at home in the middle.
  final double journey;

  /// The artwork, which is the game's own.
  static const String artwork = 'assets/images/logo.png';

  @override
  Widget build(BuildContext context) {
    final palette = ScenePalette.of(context);
    final placement = MarkTravel.at(
      journey,
      viewport: MediaQuery.sizeOf(context),
    );
    final bounds = placement.bounds;

    return Positioned(
      left: bounds.left,
      top: bounds.top,
      width: bounds.width,
      height: bounds.height,
      child: IgnorePointer(
        child: Image.asset(
          artwork,
          // Cut out of the ground and lit, rather than a coloured shape
          // sitting on it — the same treatment the scene gives it, so the
          // mark the visitor arrives with is the mark they left with.
          color: palette.background,
          colorBlendMode: BlendMode.srcIn,
          fit: BoxFit.fill,
          // Off at this size, and it is a silhouette rather than a
          // photograph — the smoothing costs more than it returns.
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
