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
    VoidCallback? onOpen,
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
          onOpen: onOpen,
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

  group('open', () {
    final linked = order.frames.firstWhere((f) => f.project?.hasLink ?? false);

    testWidgets('shows on a focused work that has a link, and opens it', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(focused: linked, onOpen: () => taps.add('open')),
      );

      final open = find.bySemanticsLabel('Open ${linked.project!.title}');
      expect(open, findsOneWidget);
      await tester.tap(find.textContaining('open'));
      expect(taps, <String>['open']);
    });

    testWidgets('is absent when the work has nowhere to go', (tester) async {
      // The view passes null for a work with no link; nothing is drawn, so
      // there is no dead control to press.
      final unlinked = order.frames.firstWhere(
        (f) => !(f.project?.hasLink ?? true),
      );
      await tester.pumpWidget(host(focused: unlinked));
      expect(find.textContaining('open'), findsNothing);
    });

    testWidgets('is absent while walking, with nothing focused', (
      tester,
    ) async {
      await tester.pumpWidget(host(onOpen: () => taps.add('open')));
      expect(find.textContaining('open'), findsNothing);
    });

    testWidgets('is at least a touch target', (tester) async {
      await tester.pumpWidget(host(focused: linked, onOpen: () {}));
      final size = tester.getSize(
        find.ancestor(
          of: find.textContaining('open'),
          matching: find.byType(Container),
        ).first,
      );
      expect(size.height, greaterThanOrEqualTo(44));
      expect(size.width, greaterThanOrEqualTo(44));
    });
  });
}
