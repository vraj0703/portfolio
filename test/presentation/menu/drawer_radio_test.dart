import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/data/di/dependency_manager.dart';
import 'package:portfolio/data/di/injection.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/menu/drawer_radio.dart';

void main() {
  SceneBloc? bloc;

  setUp(() async {
    DependencyManager.instance.reset();
    await initDependencies();
  });

  tearDown(() async {
    await bloc?.close();
    DependencyManager.instance.reset();
  });

  testWidgets('the drawer radio: 8/16/24 spacing, 48 dp controls '
      '(PORTFOLIO-30)', (tester) async {
    tester.view.physicalSize = const Size(411, 763);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    bloc = SceneBloc();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<SceneBloc>.value(
          value: bloc!,
          child: const Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: DrawerRadio(look: DrawerRadioLook.text),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final buttons = find.byType(TextButton);
    expect(buttons, findsNWidgets(2));
    for (final b in buttons.evaluate()) {
      final r = tester.getRect(find.byWidget(b.widget));
      expect(r.width, greaterThanOrEqualTo(48));
      expect(r.height, greaterThanOrEqualTo(48));
      // Inside the drawer's side margins.
      expect(r.left, greaterThanOrEqualTo(DrawerRadioConfig.sideMargin));
      expect(r.right, lessThanOrEqualTo(411 - DrawerRadioConfig.sideMargin));
    }

    // Clear of whatever stands above it (the close icon in the drawer).
    final first = tester.getRect(find.byType(Text).first);
    expect(first.top, greaterThanOrEqualTo(DrawerRadioConfig.topInset));

    // The controls stand a full step below the status line.
    final status = tester.getRect(find.byType(Text).at(1));
    final controls = tester.getRect(buttons.first);
    expect(
      controls.top - status.bottom,
      greaterThanOrEqualTo(DrawerRadioConfig.controlsGap - 1),
    );
  });
}
