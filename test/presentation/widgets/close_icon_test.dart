import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/presentation/widgets/close_icon.dart';

void main() {
  testWidgets('a 48 dp target, labelled close, in the ink it is given', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var pressed = 0;
    const ink = Color(0xFF123456);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CloseIcon(ink: ink, onPressed: () => pressed++),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(CloseIcon));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(find.bySemanticsLabel('close'), findsOneWidget);

    final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(svg.colorFilter, const ColorFilter.mode(ink, BlendMode.srcIn));

    await tester.tap(find.byType(CloseIcon));
    expect(pressed, 1);
    handle.dispose();
  });
}
