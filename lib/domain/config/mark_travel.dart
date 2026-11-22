import 'dart:ui';

import 'package:portfolio/domain/config/logo_config.dart';
import 'package:portfolio/domain/config/title_chrome.dart';

/// Where the mark is, and how big.
class MarkPlacement {
  const MarkPlacement({required this.centre, required this.size});

  final Offset centre;
  final Size size;

  /// The rectangle it occupies, for a widget that positions by edges.
  Rect get bounds =>
      Rect.fromCenter(center: centre, width: size.width, height: size.height);
}

/// The mark's journey between the middle of the screen and its corner.
///
/// One rule, read from two places. The title scene draws the mark through
/// Flame and the corridor draws it through Flutter — two renderers that never
/// have a frame in common — and the whole point of the mark being there is
/// that it is the *same* mark: it parks in the corner as the title takes
/// over, waits there through the gallery, and flies back to the middle when
/// the visitor asks for the contact screen. A few pixels of disagreement
/// between the two would show as a jump at the handover, which is exactly
/// the seam the mark exists to hide.
///
/// Pure, so where the mark sits at any point of that journey can be checked
/// without either renderer.
abstract final class MarkTravel {
  /// The mark's placement at [journey] through its retreat.
  ///
  /// `0` is at home, filling the middle of the screen. `1` is parked in the
  /// corner as a header mark. Anything between is on its way, and the same
  /// number read backwards is the return.
  static MarkPlacement at(double journey, {required Size viewport}) {
    final travelled = journey.clamp(0.0, 1.0);

    final width = LogoConfig.homeMarkWidthFor(
      viewportWidth: viewport.width,
      viewportHeight: viewport.height,
    );
    final home = Size(width, width * LogoConfig.markAspect);
    final parked = parkedFor(viewport, home: home);
    final homeCentre = Offset(viewport.width / 2, viewport.height / 2);

    return MarkPlacement(
      centre: Offset.lerp(homeCentre, parked.center, travelled)!,
      size: Size.lerp(home, parked.size, travelled)!,
    );
  }

  /// Where the mark parks as the header mark, for a home size of [home].
  ///
  /// A compact screen (a phone) parks it beside the action row by Material's
  /// rule ([TitleChrome.compactMarkRect]); a wider one at
  /// [LogoConfig.exitScale] of its home size, [LogoConfig.exitMargin] in, as
  /// it always has. Anchored on its middle, so the corner accounts for its
  /// own size: a mark centred on the margin would hang half off the screen.
  static Rect parkedFor(Size viewport, {required Size home}) {
    if (TitleChrome.isCompact(viewport)) {
      return TitleChrome.compactMarkRect(viewport);
    }
    final parked = home * LogoConfig.exitScale;
    return Offset(LogoConfig.exitMargin, LogoConfig.exitMargin) & parked;
  }
}
