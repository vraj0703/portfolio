import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/data/di/dependency_manager.dart';
import 'package:portfolio/data/di/injection.dart';
import 'package:portfolio/domain/contact/credits.dart';
import 'package:portfolio/domain/contact/credits_layout.dart';
import 'package:portfolio/domain/style/strings.dart';
import 'package:portfolio/presentation/screen/credits_dialog.dart';

void main() {
  const strings = DefaultAppStrings();

  setUp(() async {
    DependencyManager.instance.reset();
    await initDependencies();
  });
  tearDown(DependencyManager.instance.reset);

  testWidgets("the dialog carries Vishal's words and every known credit", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(411, 763);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CreditsDialog())),
    );
    await tester.pump();

    expect(
      strings.creditsSubtitle,
      'When creativity meets ai and boredom. Heavy lifting by ai, directed by me.',
    );
    expect(find.text(strings.creditsSubtitle), findsOneWidget);
    for (final group in Credits.groups) {
      for (final line in group.items) {
        expect(find.text(line), findsOneWidget, reason: line);
      }
    }
    // The closing lines, scrolled to, with "write to me" as the link: a
    // 48 dp target over the phrase.
    await tester.scrollUntilVisible(
      find.byKey(CreditsDialog.writeToMeKey),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final target = tester.getSize(find.byKey(CreditsDialog.writeToMeKey));
    expect(target.height, CreditsLayout.linkTarget);
    expect(target.width, greaterThanOrEqualTo(CreditsLayout.linkTarget));
    expect(
      find.textContaining(strings.creditsClosingLink, findRichText: true),
      findsOneWidget,
    );
    expect(
      '${strings.creditsClosingBefore}${strings.creditsClosingLink}'
          '${strings.creditsClosingAfter}',
      'I have tried my best to name everyone whose work this stands on. '
          'If yours is here and your name is not, I am sorry. '
          'Please write to me and I will put it right.',
    );
  });

  for (final (w, h, name) in <(double, double, String)>[
    (1440, 900, 'desktop 1440'),
    (820, 1180, 'tablet 820'),
    (411, 914, 'phone 411'),
    (320, 568, 'phone 320'),
    (914, 411, 'phone landscape'),
  ]) {
    testWidgets('$name: the width rule, and nothing overflows', (tester) async {
      tester.view.physicalSize = Size(w, h);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CreditsDialog())),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      final spec = CreditsLayout.forScreen(w, h);
      // The panel: the Material the Dialog lays inside its insets.
      final panel = tester.getSize(
        find
            .descendant(
              of: find.byType(Dialog),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(panel.width, closeTo(spec.width, 0.5));
      expect(panel.height, lessThanOrEqualTo(spec.maxHeight + 0.5));
      // The title and the close icon stay put while the body scrolls.
      final close = tester.getTopLeft(find.text(strings.madeWith));
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pump();
      expect(tester.getTopLeft(find.text(strings.madeWith)), close);
      expect(tester.takeException(), isNull);
    });
  }
}
