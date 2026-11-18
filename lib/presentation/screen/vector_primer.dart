import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:portfolio/domain/contact/contact_menu.dart';
import 'package:portfolio/presentation/menu/title_actions.dart';

/// Every drawing the title and the contact menu show, drawn once under the
/// loading curtain.
///
/// The first `SvgPicture` to build on the web runs a probe in
/// `vector_graphics` (`useHtmlRenderObject`): it rasterises a picture and
/// reads one pixel back to learn which renderer it is on. A read-back waits
/// for everything the GPU has queued, and on a phone that was 490 ms on the
/// title, right after the tap (ROG, 2026-11-17, GL census). The answer is
/// cached for the page's life, so paying it here pays it once, behind the
/// curtain; the assets are loaded and parsed on the way.
///
/// Painted, not `Offstage`: the curtain covers it, and the drawings are then
/// cached the way the title will draw them.
class VectorPrimer extends StatelessWidget {
  const VectorPrimer({super.key});

  /// The title's buttons and the contact menu's marks.
  static const List<String> drawings = <String>[
    SoundButton.speaker,
    SoundButton.mute,
    // The heart: the drawer's bar (PORTFOLIO-24), once the title's.
    'assets/vectors/heart.svg',
    MenuButton.icon,
    ...ContactMenu.drawings,
  ];

  /// Small: what is being paid for is the probe and the parse, not pixels.
  static const double size = 16;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Wrap(
        children: <Widget>[
          for (final path in drawings.toSet())
            SvgPicture.asset(path, width: size, height: size),
        ],
      ),
    );
  }
}
