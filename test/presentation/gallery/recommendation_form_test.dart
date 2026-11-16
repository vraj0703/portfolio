import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/testimonial_data.dart';
import 'package:portfolio/domain/style/strings.dart';
import 'package:portfolio/presentation/gallery/recommendation_form.dart';

void main() {
  const strings = DefaultAppStrings();
  final sent = <PendingRecommendation>[];

  Widget host() {
    sent.clear();
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => RecommendationForm.open(
                context,
                onSubmit: (r) async => sent.add(r),
              ),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(host());
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  testWidgets('name and words are needed; nothing goes without them', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text(strings.recommendSubmit));
    await tester.pumpAndSettle();

    expect(sent, isEmpty);
    expect(find.text(strings.recommendRequired), findsNWidgets(2));
  });

  testWidgets('a complete form hands over its words and says what to do', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(field(strings.recommendName), 'Asha');
    await tester.enterText(field(strings.recommendRole), 'Lead, Acme');
    await tester.enterText(
      field(strings.recommendRelationship),
      'Managed Vishal',
    );
    await tester.enterText(field(strings.recommendWords), 'Calm and kind.');
    await tester.tap(find.text(strings.recommendSubmit));
    await tester.pumpAndSettle();

    expect(sent, hasLength(1));
    expect(sent.single.name, 'Asha');
    expect(sent.single.words, 'Calm and kind.');
    expect(find.text(strings.recommendDone), findsOneWidget);

    await tester.tap(find.text(strings.recommendClose));
    await tester.pumpAndSettle();
    expect(find.byType(RecommendationForm), findsNothing);
  });

  testWidgets('the keyboard reaches every field in order', (tester) async {
    await open(tester);

    // The name field takes focus on opening; tab walks the rest.
    final labels = <String>[
      strings.recommendName,
      strings.recommendRole,
      strings.recommendRelationship,
      strings.recommendWords,
    ];
    for (var i = 0; i < labels.length; i++) {
      final focused = FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<TextFormField>();
      expect(focused, isNotNull, reason: 'nothing focused at field $i');
      final at = tester.widget<TextFormField>(field(labels[i]));
      expect(identical(focused, at), isTrue, reason: 'field $i');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
  });

  testWidgets('fits a 390 wide phone without overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await open(tester);
    expect(tester.takeException(), isNull);
    final dialog = tester.getRect(find.byType(Dialog));
    expect(dialog.left, greaterThanOrEqualTo(0));
    expect(dialog.right, lessThanOrEqualTo(390));
  });
}
