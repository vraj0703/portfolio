import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/presentation/gallery/gallery_view.dart';

import '../widgets/loading_test_host.dart';

void main() {
  // The corridor itself needs a GPU, which a test harness cannot provide, so
  // what is exercised here is the branch taken *before* the scene is ready —
  // which happens to be the branch the leak lived in.
  testWidgets('the gate is fed even before the corridor is ready', (
    tester,
  ) async {
    await tester.pumpWidget(loadingHost(const GalleryView()));

    // Whichever branch the harness lands in — the stand-in on a slow machine,
    // or the failure screen here, where there is no GPU to build a corridor
    // with — the gate has to be in front of it.
    // The regression. The scroll gate was mounted around the finished scene
    // only, so for as long as the placeholder was up the gate saw nothing:
    // the tail of the previous stage's gesture flowed past unobserved, its
    // activity clock stayed frozen at the handover, and the first event the
    // gate did see looked like the pause it was waiting for — arming it in
    // the middle of the very gesture it exists to discard.
    // The gate is the listener that handles pointer *signals*; the overlay's
    // gesture detectors each bring a Listener of their own, so counting them
    // says nothing.
    final gate = find.byWidgetPredicate(
      (w) => w is Listener && w.onPointerSignal != null,
      description: 'the scroll gate',
    );

    expect(
      gate,
      findsOneWidget,
      reason: 'a branch outside the Listener leaves the gate blind',
    );
    expect(
      find.descendant(of: gate, matching: find.byType(ColoredBox)),
      findsWidgets,
      reason: 'whatever is on screen must sit inside the gate, not beside it',
    );
  });

  testWidgets('the placeholder swallows the gesture rather than ignoring it', (
    tester,
  ) async {
    await tester.pumpWidget(loadingHost(const GalleryView()));

    final listener = tester.widget<Listener>(
      find.byWidgetPredicate(
        (w) => w is Listener && w.onPointerSignal != null,
      ),
    );

    // Hit-test behaviour is the other half of it: a Listener that defers to a
    // child which does not take part in hit testing never receives a pointer
    // signal at all, and is a gate in name only.
    expect(listener.behavior, HitTestBehavior.opaque);
    expect(listener.onPointerSignal, isNotNull);
  });
}
