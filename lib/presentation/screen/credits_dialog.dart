import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:portfolio/domain/contact/contact_menu.dart';
import 'package:portfolio/domain/contact/credits.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/domain/style/text_styles.dart';
import 'package:portfolio/domain/style/strings.dart';

/// Opens the credits, from the heart on the contact menu.
///
/// A function rather than a widget because that is what it is — the dialog
/// itself is [CreditsDialog] below, and this is only the route. Kept next to
/// it so the barrier colour and the dialog's own ground are decided in one
/// place.
Future<void> showCreditsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    // Dark enough that the scene reads as having stepped back, light enough
    // that it has not gone away — the visitor is still standing on the
    // contact screen and should be able to see that they are.
    barrierColor: context.colors.creditsBarrier,
    builder: (context) => const CreditsDialog(),
  );
}

/// What this was built out of.
class CreditsDialog extends StatelessWidget {
  const CreditsDialog({super.key});

  static const double maxWidth = 460;
  static const double markSize = 26;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.typography;
    final strings = context.strings;

    return Dialog(
      backgroundColor: colors.creditsPanel,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        // A hairline rather than a shadow. The ground behind is the same
        // colour as the dialog, so without an edge the panel has no outline
        // at all and the credits read as printed on the scene.
        side: BorderSide(color: colors.creditsBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 20, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  // The title is the sentence the heart finishes, so the
                  // mark comes after the words rather than standing in
                  // front of them as an ornament.
                  Text(
                    strings.madeWith,
                    style: type.creditsTitle.copyWith(
                      color: colors.creditsTitle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SvgPicture.asset(
                    ContactMenu.heartIcon,
                    height: markSize,
                    colorFilter: ColorFilter.mode(
                      colors.creditsTitle,
                      BlendMode.srcIn,
                    ),
                  ),
                  const Spacer(),

                  // In the header rather than under the list. The credits
                  // grow every time something new is pulled in, and a way
                  // out that sits below them is a way out that scrolls off
                  // the bottom of a phone the first time the list is long
                  // enough to need scrolling.
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      strings.creditsClose,
                      style: type.creditsAction.copyWith(
                        color: colors.creditsAction,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                strings.creditsSubtitle,
                style: type.creditsSubtitle.copyWith(
                  color: colors.creditsSubtitle,
                ),
              ),
              const SizedBox(height: 22),

              for (final group in Credits.groups)
                _CreditGroupBlock(group: group),
            ],
          ),
        ),
      ),
    );
  }
}

/// One heading and the things credited under it.
class _CreditGroupBlock extends StatelessWidget {
  const _CreditGroupBlock({required this.group});

  final CreditGroup group;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.typography;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            group.heading.toUpperCase(),
            style: type.creditsHeading.copyWith(
              color: colors.creditsHeading,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in group.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                item,
                style: type.creditsBody.copyWith(color: colors.creditsBody),
              ),
            ),
        ],
      ),
    );
  }
}
