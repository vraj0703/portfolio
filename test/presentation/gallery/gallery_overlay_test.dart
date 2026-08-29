import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';
import 'package:portfolio/domain/gallery/walk_order.dart';
import 'package:portfolio/presentation/gallery/gallery_overlay.dart';

void main() {
  final order = WalkOrder(GalleryLayout.build());
  final taps = <String>[];

  Widget host({
    Placement? focused,
    bool canGoBack = true,
    bool canGoForward = true,
    bool mirrored = false,
  }) {
    taps.clear();
    return MaterialApp(
      home: Scaffold(
        body: GalleryOverlay(
          focused: focused,
          canGoBack: canGoBack,
          canGoForward: canGoForward,
          onBack: () => taps.add('back'),
          onExit: () => taps.add('exit'),
          onForward: () => taps.add('forward'),
          mirrored: mirrored,
          asFallback: true,
        ),
      ),
    );
  }

  testWidgets('the controls appear only with a piece focused', (tester) async {
    // A permanent bar of dead buttons reads as a broken interface.
    await tester.pumpWidget(host());
    expect(find.text('✕'), findsNothing);

    await tester.pumpWidget(host(focused: order.frames.first));
    expect(find.text('✕'), findsOneWidget);
  });

  testWidgets('all three controls answer', (tester) async {
    await tester.pumpWidget(host(focused: order.frames[1]));

    await tester.tap(find.text('‹'));
    await tester.tap(find.text('✕'));
    await tester.tap(find.text('›'));

    expect(taps, <String>['back', 'exit', 'forward']);
  });

  testWidgets('an unavailable control is hidden, not disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(focused: order.frames.first, canGoBack: false),
    );

    expect(find.text('‹'), findsNothing);

    // The others still work while one end is closed.
    await tester.tap(find.text('›'));
    expect(taps, <String>['forward']);
  });

  testWidgets('hiding a control does not move the others', (tester) async {
    // Its space is kept. Removing the box outright slides ✕ off centre, so
    // the control under the pointer becomes a different control between one
    // piece and the next.
    await tester.pumpWidget(host(focused: order.frames.first));
    final withBoth = tester.getCenter(find.text('✕'));

    await tester.pumpWidget(
      host(focused: order.frames.first, canGoBack: false),
    );

    expect(tester.getCenter(find.text('✕')), withBoth);
  });

  group('on the right-hand wall', () {
    // The camera reads that wall from the other side, so the corridor runs
    // the opposite way across the screen: deeper in *appears* to be left.
    testWidgets('the arrows swap sides', (tester) async {
      await tester.pumpWidget(host(focused: order.frames[1], mirrored: true));

      await tester.tap(find.text('‹'));
      expect(taps, <String>['forward']);

      await tester.tap(find.text('›'));
      expect(taps, <String>['forward', 'back']);
    });

    testWidgets('the live arrow is the one nearer the way on', (tester) async {
      // At the first piece there is nothing behind, so the only arrow shown
      // must be the one that goes deeper — and on this wall that is ‹.
      await tester.pumpWidget(
        host(focused: order.frames[1], mirrored: true, canGoBack: false),
      );

      expect(find.text('‹'), findsOneWidget);
      expect(find.text('›'), findsNothing);
    });
  });
}
