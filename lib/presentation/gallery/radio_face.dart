import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';
import 'package:portfolio/domain/radio/radio_player.dart';
import 'package:portfolio/domain/style/text_styles.dart';
import 'package:portfolio/presentation/gallery/wall_text.dart';

/// The radio's face, cut into the wall.
///
/// The same lettering as the way out and the invitation — [WallText], in
/// [AppTypography.wallSign], engraved and inlaid. It was neon for a while, on
/// the reasoning that a device should look switched on, and that was wrong
/// for a simpler reason than it was right: this room has exactly one way of
/// writing on a wall, and a second one does not read as a different kind of
/// object, it reads as a different room.
///
/// Baked like the signage, and *re-baked* on every change, which is the one
/// thing here a wall does not do. Cheap enough: the image is small, and it
/// happens when somebody presses something.
abstract final class RadioFace {
  /// How large the baked image is.
  ///
  /// Shaped to the panel it goes on at the same pixels-per-unit the room's
  /// signs use, so a letter here is the same size as a letter on those.
  static const double pixelsPerUnit = 600;

  static int get width => (GalleryLayout.radioWidth * pixelsPerUnit).round();
  static int get height => (GalleryLayout.radioHeight * pixelsPerUnit).round();

  /// How far apart the rows sit.
  static const double stationGap = 52;

  /// Where the two controls go — read from [GalleryLayout], not decided here.
  ///
  /// The same fraction places the tap targets in the room. One number, because
  /// a picture of a button and the place that button can be pressed have no
  /// business being two: they were, briefly, and the drawn controls ended up
  /// an eighth of a metre from their targets.
  static const double controlOffset = GalleryLayout.radioControlOffset;

  static Future<ui.Image> render({
    required RadioState state,
    required AppTypography type,
  }) {
    // The station name is set at the sign size exactly, not a size near it.
    // It hangs across the hall's door from LET'S CONNECT, and the two are a
    // pair; a pair whose letters are four fifths the height of each other
    // does not read as emphasis, it reads as the smaller one being further
    // away. It was 132 against the sign's 170, and that is what the hall
    // looked like.
    //
    // The rows under it keep their proportions to it, so the face is one
    // object scaled rather than a heading with two odd lines beneath.
    final station = type.wallSign;
    final status = type.wallSign.copyWith(fontSize: 93, letterSpacing: 12);
    final control = type.wallSign.copyWith(fontSize: 106, letterSpacing: 8);

    return WallText.render(
      width: width,
      height: height,
      gap: stationGap,
      lines: <EngravedLine>[
        EngravedLine(
          TextSpan(text: state.tuned.name.toUpperCase(), style: station),
        ),
        EngravedLine(TextSpan(text: state.readout, style: status)),
        // The play control says what pressing it will do, not what the radio
        // is doing. A button labelled with the current state reads as a
        // description until somebody presses it to find out.
        EngravedLine(
          TextSpan(
            text: state.isPlaying || state.isTuning ? 'STOP' : 'PLAY',
            style: control,
          ),
          shift: -controlOffset,
        ),
        // On the same row as the one before it, either side of the middle.
        EngravedLine(
          TextSpan(text: 'NEXT', style: control),
          shift: controlOffset,
          sameRow: true,
        ),
      ],
    );
  }
}
