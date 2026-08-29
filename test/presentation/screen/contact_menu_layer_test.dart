import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/core/di/dependency_manager.dart';
import 'package:portfolio/core/di/injection.dart';
import 'package:portfolio/domain/contact/contact_menu.dart';
import 'package:portfolio/domain/style/strings.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/screen/contact_menu_layer.dart';
import 'package:portfolio/presentation/screen/credits_dialog.dart';

void main() {
  const strings = DefaultAppStrings();
  SceneBloc? created;

  setUp(() async {
    DependencyManager.instance.reset();
    await initDependencies();
  });

  tearDown(() async {
    await created?.close();
    created = null;
    DependencyManager.instance.reset();
  });

  Widget host() {
    created = SceneBloc();
    return MaterialApp(
      home: BlocProvider<SceneBloc>.value(
        value: created!,
        child: const Scaffold(body: ContactMenuLayer()),
      ),
    );
  }

  /// Puts the scene on the contact screen without walking the whole sequence.
  Future<void> arrive(WidgetTester tester) async {
    await tester.pumpWidget(host());
    created!.emit(const SceneState.contact());
    await tester.pump();
    // Past the fade-in, so the row is at full strength and hit-testable.
    await tester.pumpAndSettle();
  }

  testWidgets('draws nothing until the contact screen is reached', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pump();

    // It sits in the scene's stack for the whole visit. Costing a layer of
    // scrim and seven hit targets on every other screen is the failure this
    // guards against.
    expect(find.text(strings.contactGithub), findsNothing);
    expect(find.byType(SvgPicture), findsNothing);
  });

  testWidgets('offers all seven destinations', (tester) async {
    await arrive(tester);

    for (final word in <String>[
      strings.contactCv,
      strings.contactEmail,
      strings.contactGithub,
      strings.contactLinkedIn,
    ]) {
      expect(find.text(word), findsOneWidget);
    }

    // Three marks, and a dot between every neighbouring pair.
    expect(
      find.byType(SvgPicture),
      findsNWidgets(
        ContactMenu.icons.length + ContactMenu.entries.length - 1,
      ),
    );
  });

  testWidgets('the gallery mark walks back into the corridor', (tester) async {
    await arrive(tester);

    await tester.tap(
      find.bySemanticsLabel(
        strings.contactMarkLabel(ContactDestination.gallery),
      ),
    );
    await tester.pump();

    expect(created!.state, isA<Gallery>());
  });

  testWidgets('the home mark starts the logo screen leaving', (tester) async {
    await arrive(tester);

    await tester.tap(
      find.bySemanticsLabel(strings.contactMarkLabel(ContactDestination.home)),
    );
    await tester.pump();

    expect(created!.state, isA<LogoOverlayRemoving>());
  });

  testWidgets('the heart opens the credits', (tester) async {
    await arrive(tester);

    await tester.tap(
      find.bySemanticsLabel(
        strings.contactMarkLabel(ContactDestination.credits),
      ),
    );
    await tester.pumpAndSettle();

    // Scoped to the dialog. The menu behind it reads "Made with" too — that
    // is the point of the entry — so an unscoped finder would pass whether
    // or not the dialog had opened at all.
    final title = find.descendant(
      of: find.byType(CreditsDialog),
      matching: find.text(strings.madeWith),
    );
    expect(title, findsOneWidget);
    expect(find.text(strings.creditsSubtitle), findsOneWidget);

    await tester.tap(find.text(strings.creditsClose));
    await tester.pumpAndSettle();
    expect(find.byType(CreditsDialog), findsNothing);
  });

  testWidgets('fits on a phone without overrunning its own rules', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await arrive(tester);

    // The row shrinks to fit rather than spilling. A menu that overflows is
    // reported as a rendering error rather than as a layout choice, and it
    // is the whole reason the gap is derived from the viewport.
    expect(tester.takeException(), isNull);
    expect(find.text(strings.contactLinkedIn), findsOneWidget);
  });
}
