import 'package:portfolio/domain/contact/contact_links.dart';
import 'package:portfolio/domain/analytics/analytics.dart';
import 'package:portfolio/data/di/dependency_manager.dart';
import 'package:portfolio/presentation/widgets/close_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:portfolio/domain/audio/app_audio.dart';
import 'package:portfolio/domain/contact/contact_menu.dart';
import 'package:portfolio/domain/contact/credits.dart';
import 'package:portfolio/domain/contact/credits_layout.dart';
import 'package:portfolio/domain/style/panel_shape.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/domain/style/text_styles.dart';
import 'package:portfolio/domain/style/strings.dart';

/// Opens the credits, from the heart on the contact menu.
///
/// A function rather than a widget because that is what it is — the dialog
/// itself is [CreditsDialog] below, and this is only the route. Kept next to
/// it so the barrier colour and the dialog's own ground are decided in one
/// place.
Future<void> showCreditsDialog(BuildContext context) async {
  // While it is up, the contact links stand aside (CreditsDialog.open): on a
  // phone their panel showed under and below the dialog's edge, and two
  // panels of the same colour read as one muddle.
  CreditsDialog.open.value = true;
  try {
    await _show(context);
  } finally {
    CreditsDialog.open.value = false;
  }
}

Future<void> _show(BuildContext context) {
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

  static const double markSize = 26;

  /// Whether the dialog is up: what the contact links watch to stand aside.
  static final ValueNotifier<bool> open = ValueNotifier<bool>(false);

  /// The key of the hit target over "write to me" (for tests).
  static const Key writeToMeKey = ValueKey<String>('credits-write-to-me');

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.typography;
    final strings = context.strings;
    final screen = MediaQuery.sizeOf(context);
    final safe = MediaQuery.paddingOf(context);
    final spec = CreditsLayout.forScreen(
      screen.width,
      screen.height,
      safeLeft: safe.left,
      safeRight: safe.right,
      safeTop: safe.top,
      safeBottom: safe.bottom,
    );

    final groups = Credits.groups;
    final Widget body;
    if (spec.columns == 2) {
      // Split where the lines balance, keeping each group whole.
      final total = groups.fold<int>(0, (n, g) => n + g.items.length + 1);
      var run = 0;
      var split = groups.length;
      for (var i = 0; i < groups.length; i++) {
        run += groups[i].items.length + 1;
        if (run * 2 >= total) {
          split = i + 1;
          break;
        }
      }
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final g in groups.sublist(0, split))
                  _CreditGroupBlock(group: g),
              ],
            ),
          ),
          const SizedBox(width: 28),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final g in groups.sublist(split))
                  _CreditGroupBlock(group: g),
              ],
            ),
          ),
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final group in groups) _CreditGroupBlock(group: group),
        ],
      );
    }

    return Dialog(
      backgroundColor: colors.creditsPanel,
      insetPadding: EdgeInsets.fromLTRB(
        spec.insetLeft,
        spec.insetTop,
        spec.insetRight,
        spec.insetBottom,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PanelShape.radius),
        // A hairline rather than a shadow. The ground behind is the same
        // colour as the dialog, so without an edge the panel has no outline
        // at all and the credits read as printed on the scene.
        side: BorderSide(color: colors.creditsBorder),
      ),
      // Its width and height from the screen's shape (CreditsLayout): a
      // reading measure on a desktop, nearly the full width of a phone, and
      // never taller than most of the screen.
      child: SizedBox(
        width: spec.width,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: spec.maxHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // The title and the way out stay put while the body scrolls:
              // a close that scrolled off the top of a phone would leave the
              // visitor hunting for it.
              Padding(
                padding: EdgeInsets.fromLTRB(
                  spec.paddingH,
                  20,
                  spec.paddingH - 8,
                  0,
                ),
                child: Row(
                  children: <Widget>[
                    // The title is the sentence the heart finishes, so the
                    // mark comes after the words rather than standing in
                    // front of them as an ornament. It may wrap on the
                    // narrowest phone rather than push the close off.
                    Expanded(
                      child: Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              strings.madeWith,
                              style: type.creditsTitle.copyWith(
                                color: colors.creditsTitle,
                              ),
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
                        ],
                      ),
                    ),
                    CloseIcon(
                      ink: colors.creditsAction,
                      onPressed: () {
                        // Answers the step the heart took to open this.
                        context.audio.play(AudioCue.previous);
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    spec.paddingH,
                    6,
                    spec.paddingH,
                    8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        strings.creditsSubtitle,
                        style: type.creditsSubtitle.copyWith(
                          color: colors.creditsSubtitle,
                        ),
                      ),
                      const SizedBox(height: 22),
                      body,

                      // Vishal's closing lines; "write to me" opens the same
                      // e-mail the contact row does.
                      const SizedBox(height: 4),
                      const _Closing(),
                      const SizedBox(height: 4),
                    ],
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
            style: type.creditsHeading.copyWith(color: colors.creditsHeading),
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

/// The dialog's last words, with the way to write in them.
///
/// "write to me" stays a phrase in the sentence, and its tap target is a
/// full 48 dp (CreditsLayout.linkTarget): a box laid over the phrase where
/// the text actually sets it, rather than a taller line in the paragraph.
class _Closing extends StatelessWidget {
  const _Closing();

  /// Room above and below the paragraph, so a target over its first or
  /// last line still lies inside this widget (a hit outside a box misses).
  static const double reach = 14;

  void _write() {
    locate<SiteEvents>().contactLinkClicked('email');
    locate<ContactLinks>().composeEmail();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final style = context.typography.creditsBody.copyWith(
      color: context.colors.creditsBody,
    );
    final before = strings.creditsClosingBefore;
    final link = strings.creditsClosingLink;
    final span = TextSpan(
      style: style,
      children: <InlineSpan>[
        TextSpan(text: before),
        TextSpan(
          text: link,
          style: style.copyWith(decoration: TextDecoration.underline),
        ),
        TextSpan(text: strings.creditsClosingAfter),
      ],
    );
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: span,
          textDirection: direction,
          textScaler: scaler,
        )..layout(maxWidth: constraints.maxWidth);
        final boxes = painter.getBoxesForSelection(
          TextSelection(
            baseOffset: before.length,
            extentOffset: before.length + link.length,
          ),
        );
        painter.dispose();
        const target = CreditsLayout.linkTarget;
        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: reach),
              child: Text.rich(span, textScaler: scaler),
            ),
            for (final (i, box) in boxes.indexed)
              Positioned(
                left: box.right - box.left >= target
                    ? box.left
                    : (box.left + box.right - target) / 2,
                top: reach + (box.top + box.bottom - target) / 2,
                width: box.right - box.left >= target
                    ? box.right - box.left
                    : target,
                height: target,
                child: Semantics(
                  link: true,
                  label: link,
                  child: GestureDetector(
                    key: i == 0 ? CreditsDialog.writeToMeKey : null,
                    behavior: HitTestBehavior.opaque,
                    onTap: _write,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
