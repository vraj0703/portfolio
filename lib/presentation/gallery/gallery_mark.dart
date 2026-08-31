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
///
/// Drawn once at its full size and *transformed* into place rather than laid
/// out at each size in turn. Sixty frames of a widget resizing itself is
/// sixty rasterisations and sixty repaints of everything around it, which on
/// top of a 3D scene still rendering behind is what made the flight stutter.
/// A cached raster under a changing matrix costs a matrix.
class GalleryMark extends StatelessWidget {
  const GalleryMark({required this.journey, super.key});

  /// `1` parked in the corner, `0` at home in the middle.
  final double journey;

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final home = MarkTravel.at(0, viewport: viewport);
    final now = MarkTravel.at(journey, viewport: viewport);

    return Positioned.fill(
      // Inside the `Positioned`, never outside it. A boundary is a render
      // object, so one placed between this and the `Stack` leaves the
      // `Positioned` with no `Stack` to give its parent data to — which
      // throws at layout, where nothing static catches it.
      child: RepaintBoundary(
        child: IgnorePointer(
          child: Align(
            alignment: Alignment.topLeft,
            child: Transform(
              // Scaled down from home rather than up from parked: the raster is
              // taken at the larger of the two, so the mark is never asked to
              // invent detail it was not drawn with.
              transform: Matrix4.identity()
                ..translateByDouble(now.bounds.left, now.bounds.top, 0, 1)
                ..scaleByDouble(
                  now.size.width / home.size.width,
                  now.size.height / home.size.height,
                  1,
                  1,
                ),
              child: SizedBox(
                width: home.size.width,
                height: home.size.height,
                // The boundary is the whole point. Under it the artwork is
                // rasterised once and reused; over it the transform is all
                // that changes from frame to frame, and neither the corridor
                // behind nor the chrome beside is dragged into the repaint.
                child: const RepaintBoundary(child: _MarkArtwork()),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The artwork itself, kept apart so it rebuilds for nothing.
///
/// Const, and const on purpose: the flight rebuilds [GalleryMark] on every
/// frame, and an identical child widget means the element is reused, the
/// image is not resolved again, and the cached layer beneath survives.
class _MarkArtwork extends StatelessWidget {
  const _MarkArtwork();

  static const String artwork = 'assets/images/logo.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      artwork,
      // Cut out of the ground and lit, rather than a coloured shape sitting
      // on it — the same treatment the scene gives it, so the mark the
      // visitor arrives with is the mark they left with.
      color: ScenePalette.of(context).background,
      colorBlendMode: BlendMode.srcIn,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.medium,
    );
  }
}
