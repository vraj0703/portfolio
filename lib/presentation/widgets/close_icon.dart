import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:portfolio/domain/style/strings.dart';

/// The way out, as the icon family's cross (PORTFOLIO-26).
///
/// One widget for every "close": the drawer's and the credits dialog's. The
/// pi seat drew it in the family of the existing 24x24 icons (1.5 line,
/// round ends, the family's small break); it is drawn in the ink of the
/// controls beside it, on a 48 dp target, and a screen reader hears
/// "close".
class CloseIcon extends StatelessWidget {
  const CloseIcon({super.key, required this.ink, required this.onPressed});

  static const String icon = 'assets/vectors/close.svg';
  static const double glyph = 24;
  static const double target = 48;

  /// The ink of the controls beside it (the drawer's soft text ink, the
  /// credits' action ink): the same rule the words it replaces followed.
  final Color ink;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.strings.menuClose,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onPressed,
        radius: target / 2,
        child: SizedBox(
          width: target,
          height: target,
          child: Center(
            child: SvgPicture.asset(
              icon,
              height: glyph,
              colorFilter: ColorFilter.mode(ink, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }
}
