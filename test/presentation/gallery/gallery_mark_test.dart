import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/config/logo_config.dart';
import 'package:portfolio/domain/config/mark_travel.dart';
import 'package:portfolio/presentation/gallery/gallery_mark.dart';

/// Where the artwork actually lands on screen.
///
/// Not the widget's own box: [GalleryMark] fills the stack and places the
/// artwork with a transform, so that the raster can be cached and only a
/// matrix changes as it flies. Measuring the outer box would measure the
/// screen.
Rect markRect(WidgetTester tester) => tester.getRect(find.byType(Image));

void main() {
  /// The mark inside a Stack, as the corridor mounts it.
  Widget host(double journey) => MaterialApp(
    home: Stack(
      fit: StackFit.expand,
      children: <Widget>[GalleryMark(journey: journey)],
    ),
  );

  testWidgets('lays out where the travel rule says', (tester) async {
    // `GalleryMark` returns a `Positioned`, and it reaches the Stack through
    // two widgets that build no render object of their own. That is legal
    // and it is not obviously legal, so it is worth one test — a parent-data
    // widget that loses its Stack throws at layout, where nothing static
    // catches it.
    await tester.pumpWidget(host(1));

    final rect = markRect(tester);
    final expected = MarkTravel.at(
      1,
      viewport: tester.view.physicalSize / tester.view.devicePixelRatio,
    ).bounds;

    expect(rect.left, closeTo(expected.left, 0.5));
    expect(rect.top, closeTo(expected.top, 0.5));
    expect(rect.width, closeTo(expected.width, 0.5));
  });

  testWidgets('parks in the corner at the margin', (tester) async {
    await tester.pumpWidget(host(1));

    final rect = markRect(tester);
    expect(rect.left, closeTo(LogoConfig.exitMargin, 0.5));
    expect(rect.top, closeTo(LogoConfig.exitMargin, 0.5));
  });

  testWidgets('fills the middle when it has flown home', (tester) async {
    await tester.pumpWidget(host(0));

    final rect = markRect(tester);
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;

    expect(rect.center.dx, closeTo(screen.width / 2, 0.5));
    expect(rect.center.dy, closeTo(screen.height / 2, 0.5));
    expect(rect.width, greaterThan(LogoConfig.exitMargin * 2));
  });

  testWidgets('never answers a tap', (tester) async {
    // It is a header mark, not a control. Left hit-testable it would swallow
    // clicks meant for the wall behind it — and once it has flown home it
    // covers the middle of the screen.
    await tester.pumpWidget(host(0));

    expect(
      find.descendant(
        of: find.byType(GalleryMark),
        matching: find.byType(IgnorePointer),
      ),
      findsOneWidget,
    );
  });
}
