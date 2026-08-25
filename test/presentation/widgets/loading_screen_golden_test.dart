import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/presentation/widgets/loading_screen.dart';

import 'loading_test_host.dart';

/// Golden renders of the loading curtain.
///
/// The curtain is almost entirely visual — aura strength, bloom, the inverted
/// mark, and the swell-and-flash exit all vary continuously, and none of that
/// is expressible as a find-by-text assertion. Goldens are the only cheap way
/// to catch a regression in it.
///
/// Regenerate after an intentional visual change:
/// `flutter test --update-goldens test/presentation/widgets/loading_screen_golden_test.dart`
void main() {
  Future<void> render(
    WidgetTester tester, {
    required double progress,
    required double exit,
    required String name,
  }) async {
    tester.view
      ..physicalSize = const Size(1280, 720)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      loadingHost(
        // Composited over black, as it is in the app: the curtain sits
        // behind this. Without it the widget's own backdrop — which turns
        // semi-transparent during the exit — would be captured over the
        // harness's white ground, and every exit frame would read as a grey
        // wash the product never shows.
        ColoredBox(
          color: const Color(0xFF000000),
          child: LoadingScreen(progress: progressAt(progress), exit: exit),
        ),
      ),
    );

    // Let the smoothing tween land on its target before capturing.
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(LoadingScreen),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  group('loading', () {
    for (final percent in <int>[1, 50, 100]) {
      testWidgets('bar at $percent%', (tester) async {
        await render(
          tester,
          progress: percent / 100,
          exit: 0,
          name: 'loading_$percent',
        );
      });
    }
  });

  group('exit', () {
    // The bar is complete throughout the exit — it only plays once loading
    // has finished.
    for (final stage in <int>[15, 40, 70]) {
      testWidgets('at $stage%', (tester) async {
        await render(tester, progress: 1, exit: stage / 100, name: 'exit_$stage');
      });
    }
  });
}
