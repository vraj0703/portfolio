import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/skill_data.dart';
import 'package:portfolio/presentation/gallery/skill_caption.dart';

void main() {
  Widget host(Skill? skill) =>
      MaterialApp(home: Scaffold(body: SkillCaption(skill: skill)));

  final shortened = GallerySkills.all.firstWhere((s) => s.name != s.label);

  testWidgets('names a shortened key in full, with its kind', (tester) async {
    // The caps carry no legend and some labels are cut to fit (TS, CF), so
    // the caption is where a key says what it is.
    await tester.pumpWidget(host(shortened));

    expect(find.text(shortened.name), findsOneWidget);
    expect(find.text(shortened.label), findsNothing);
  });

  testWidgets('and announces it to a screen reader', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(shortened));

    expect(
      find.bySemanticsLabel(RegExp('^${RegExp.escape(shortened.name)}, ')),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('says nothing with no key in hand', (tester) async {
    await tester.pumpWidget(host(null));
    expect(find.byType(Text), findsNothing);
  });
}
