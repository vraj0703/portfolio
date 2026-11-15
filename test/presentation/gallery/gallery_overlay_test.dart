import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    bool reading = false,
    bool withLink = false,
    Size size = const Size(1280, 800),
  }) {
    taps.clear();
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
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
            reading: reading,
            onRead: () => taps.add('read'),
            onCloseSheet: () => taps.add('close sheet'),
            onOpenProject: withLink ? () => taps.add('open') : null,
          ),
        ),
      ),
    );
  }

  Placement pieceFor(String id) =>
      order.frames.firstWhere((f) => f.project?.id == id);

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

  testWidgets('an unavailable control is hidden, not disabled', (tester) async {
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

  testWidgets('no floating open control: the link is on the sheet', (
    tester,
  ) async {
    final linked = order.frames.firstWhere((f) => f.project?.hasLink ?? false);
    await tester.pumpWidget(host(focused: linked, withLink: true));
    expect(find.textContaining('Open the project'), findsNothing);
  });

  group('the sheet', () {
    testWidgets('"Read the case" is offered on a finished piece', (
      tester,
    ) async {
      await tester.pumpWidget(host(focused: pieceFor('tantr')));
      await tester.tap(find.text('Read the case'));
      expect(taps, <String>['read']);
    });

    testWidgets('a piece in preparation has no sheet', (tester) async {
      await tester.pumpWidget(host(focused: pieceFor('creative-works')));
      expect(find.text('Read the case'), findsNothing);
      // Not even when asked: there is no case to show.
      await tester.pumpWidget(
        host(focused: pieceFor('creative-works'), reading: true),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CaseSheet), findsNothing);
    });

    testWidgets('nothing is offered in the corridor', (tester) async {
      await tester.pumpWidget(host());
      expect(find.text('Read the case'), findsNothing);
      expect(find.byType(CaseSheet), findsNothing);
    });

    testWidgets('opens with the case in real text', (tester) async {
      final piece = pieceFor('tantr');
      final project = piece.project!;
      await tester.pumpWidget(host(focused: piece, reading: true, withLink: true));
      await tester.pumpAndSettle();

      expect(find.byType(CaseSheet), findsOneWidget);
      expect(find.text(project.title), findsOneWidget);
      expect(find.text(project.summary), findsOneWidget);
      for (final stat in project.stats) {
        expect(find.text(stat), findsOneWidget, reason: stat);
      }
      for (final tag in project.stack) {
        expect(find.text(tag), findsOneWidget, reason: tag);
      }
      // Selectable, so a visitor can copy from it.
      expect(find.byType(SelectionArea), findsOneWidget);
      // And "Read the case" is gone while it is open.
      expect(find.text('Read the case'), findsNothing);
    });

    testWidgets('carries the link out only when there is one', (tester) async {
      await tester.pumpWidget(
        host(focused: pieceFor('tantr'), reading: true, withLink: true),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Open the project'));
      expect(taps, <String>['open']);

      await tester.pumpWidget(
        host(focused: pieceFor('shunya-systems'), reading: true),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Open the project'), findsNothing);
    });

    testWidgets('leaves an empty stack off rather than announcing it', (
      tester,
    ) async {
      final piece = pieceFor('twin-health');
      await tester.pumpWidget(host(focused: piece, reading: true));
      await tester.pumpAndSettle();
      expect(find.text(piece.project!.summary), findsOneWidget);
      expect(find.textContaining('supply'), findsNothing);
    });

    testWidgets('closes back to the piece: its button, or a press outside', (
      tester,
    ) async {
      await tester.pumpWidget(host(focused: pieceFor('tantr'), reading: true));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back to the piece'));
      expect(taps, <String>['close sheet']);

      await tester.pumpWidget(host(focused: pieceFor('tantr'), reading: true));
      await tester.pumpAndSettle();
      // The shade over the room, above the sheet.
      await tester.tapAt(const Offset(640, 20));
      expect(taps, <String>['close sheet']);
    });

    testWidgets('takes the keyboard when it opens', (tester) async {
      await tester.pumpWidget(host(focused: pieceFor('tantr'), reading: true));
      await tester.pumpAndSettle();
      // Its way back is focused, so Enter or Space closes it from the keys.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(taps, <String>['close sheet']);
    });

    testWidgets('fits a phone and keeps its buttons thumb-sized', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        host(
          focused: pieceFor('publications'),
          reading: true,
          withLink: true,
          size: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      final sheet = tester.getRect(find.byType(CaseSheet));
      expect(sheet.width, lessThanOrEqualTo(390));
      expect(sheet.height, lessThanOrEqualTo(844 * CaseSheet.maxHeightShare + 0.5));
      expect(sheet.bottom, closeTo(844, 0.5));
      for (final label in <String>['Back to the piece', 'Open the project']) {
        final button = find.ancestor(
          of: find.textContaining(label),
          matching: find.byType(TextButton),
        );
        expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
      }
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('no floating add yours: frame 1 carries it', (tester) async {
    await tester.pumpWidget(host());
    expect(find.textContaining('add yours'), findsNothing);
  });
}
