import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/presentation/widgets/loading_screen.dart';

import 'loading_test_host.dart';

void main() {
  group('label', () {
    test('pads to three digits', () {
      expect(label(0.07), 'LOADING... 007%');
      expect(label(0.42), 'LOADING... 042%');
      expect(label(1), 'LOADING... 100%');
    });

    test('never shows 000, which reads as broken rather than early', () {
      expect(label(0), 'LOADING... 001%');
      expect(label(0.004), 'LOADING... 001%');
    });

    test('keeps a constant width so the readout does not reflow', () {
      // Right-aligned text that changes length jitters on every tick.
      final widths = <int>{
        for (var i = 0; i <= 100; i++) label(i / 100).length,
      };
      expect(widths, hasLength(1));
    });
  });

  group('LoadingScreen', () {
    test('is stateless', () {
      // The project rule: no StatefulWidget until one is genuinely required.
      // Smoothing is a TweenAnimationBuilder and the exit is an input, so
      // nothing here needs State.
      expect(LoadingScreen(progress: progressAt(0)), isA<StatelessWidget>());
    });

    testWidgets('renders the mark and the readout', (tester) async {
      await tester.pumpWidget(
        loadingHost(LoadingScreen(progress: progressAt(0.5))),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsWidgets);
      expect(find.text('LOADING... 050%'), findsOneWidget);
    });

    testWidgets('smooths towards a new figure rather than snapping', (
      tester,
    ) async {
      await tester.pumpWidget(
        loadingHost(LoadingScreen(progress: progressAt(0))),
      );
      await tester.pumpAndSettle();

      // Jump the way a milestone report does.
      await tester.pumpWidget(
        loadingHost(LoadingScreen(progress: progressAt(1))),
      );
      await tester.pump(const Duration(milliseconds: 60));

      expect(
        find.text('LOADING... 100%'),
        findsNothing,
        reason: 'mid-tween the bar should still be catching up',
      );

      await tester.pumpAndSettle();
      expect(find.text('LOADING... 100%'), findsOneWidget);
    });

    testWidgets('starts from the floor rather than a blank readout', (
      tester,
    ) async {
      await tester.pumpWidget(
        loadingHost(LoadingScreen(progress: progressAt(0))),
      );
      await tester.pump();

      expect(find.text('LOADING... 001%'), findsOneWidget);
    });

    testWidgets('takes its type from the theme', (tester) async {
      // Guards the wiring: if the widget went back to a hardcoded TextStyle
      // this would keep passing only by coincidence, so assert the family the
      // theme actually specifies.
      await tester.pumpWidget(
        loadingHost(LoadingScreen(progress: progressAt(0.5))),
      );
      await tester.pumpAndSettle();

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.fontFamily, 'MonoLoading');
    });

    testWidgets('lays out without overflow on a narrow viewport', (
      tester,
    ) async {
      await tester.pumpWidget(
        loadingHost(
          LoadingScreen(progress: progressAt(0.5)),
          size: const Size(360, 640),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('exit', () {
    test('no flash while the screen is simply loading', () {
      expect(LoadingScreen.flashOpacity(0), 0);
    });

    test('bursts early rather than trailing the dissolve', () {
      final samples = <double, double>{
        for (var i = 0; i <= 20; i++)
          i / 20: LoadingScreen.flashOpacity(i / 20),
      };
      final peakAt = samples.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;

      expect(peakAt, lessThan(0.35));
      // Loose on purpose: peak brightness is a tuning dial, and pinning it
      // tightly would fail on every deliberate adjustment. What matters is
      // that a burst happens and that it happens early.
      expect(samples[peakAt], greaterThan(0.15));
    });

    test('burns out before the exit completes', () {
      expect(LoadingScreen.flashOpacity(0.8), lessThan(0.01));
      expect(LoadingScreen.flashOpacity(1), lessThan(0.01));
    });

    test('rises monotonically into the peak', () {
      var previous = 0.0;
      for (var i = 1; i <= 9; i++) {
        final value = LoadingScreen.flashOpacity(0.18 * i / 9);
        expect(value, greaterThanOrEqualTo(previous));
        previous = value;
      }
    });

    testWidgets('defaults to fully present', (tester) async {
      await tester.pumpWidget(
        loadingHost(LoadingScreen(progress: progressAt(0.5))),
      );
      await tester.pumpAndSettle();

      expect(find.text('LOADING... 050%'), findsOneWidget);
    });

    testWidgets('clears the mark once complete', (tester) async {
      await tester.pumpWidget(
        loadingHost(LoadingScreen(progress: progressAt(1), exit: 1)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsNothing);
      expect(LoadingScreen.flashOpacity(1), lessThan(0.01));

      // The readout deliberately stays in the tree to hold the column's
      // height, so it must be fully transparent rather than absent.
      final opacities = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .map((o) => o.opacity);
      expect(opacities.every((o) => o <= 0.001), isTrue);
    });

    testWidgets('the mark holds its position across the exit', (tester) async {
      // Regression guard. The readout used to collapse to zero height once it
      // faded, and because the column is centred that shortened it and
      // snapped the mark downward part-way through the exit — a visible jerk.
      final centres = <double, Offset>{};

      // Straddles the point the readout clears, which is where it jumped.
      for (final stage in <double>[0, 0.2, 0.39, 0.41, 0.6]) {
        await tester.pumpWidget(
          loadingHost(LoadingScreen(progress: progressAt(1), exit: stage)),
        );
        await tester.pump();
        centres[stage] = tester.getCenter(find.byType(Image).first);
      }

      final reference = centres[0]!;
      for (final entry in centres.entries) {
        expect(
          (entry.value.dy - reference.dy).abs(),
          lessThan(0.5),
          reason: 'mark shifted vertically at exit ${entry.key}',
        );
        expect(
          (entry.value.dx - reference.dx).abs(),
          lessThan(0.5),
          reason: 'mark shifted horizontally at exit ${entry.key}',
        );
      }
    });

    testWidgets('renders mid-exit without error', (tester) async {
      for (final stage in <double>[0.15, 0.4, 0.7]) {
        await tester.pumpWidget(
          loadingHost(LoadingScreen(progress: progressAt(1), exit: stage)),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'exit $stage');
      }
    });
  });
}

String label(double progress) {
  final pct = math.max(1, (progress * 100).round());
  return 'LOADING... ${pct.toString().padLeft(3, '0')}%';
}
