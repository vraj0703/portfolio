import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/data/di/dependency_manager.dart';
import 'package:portfolio/data/di/injection.dart';
import 'package:portfolio/domain/contact/credits.dart';
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
    // The closing lines, scrolled to, with "write to me" as the link.
    await tester.scrollUntilVisible(
      find.text(strings.creditsClosingLink),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(strings.creditsClosingLink), findsOneWidget);
    expect(
      '${strings.creditsClosingBefore}${strings.creditsClosingLink}'
          '${strings.creditsClosingAfter}',
      'I have tried my best to name everyone whose work this stands on. '
          'If yours is here and your name is not, I am sorry. '
          'Please write to me and I will put it right.',
    );
  });
}
