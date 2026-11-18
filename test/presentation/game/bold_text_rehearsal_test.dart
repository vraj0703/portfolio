import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/presentation/game/bold_text_component.dart';

/// The bold text's real draw is rehearsed while loading, so the program the
/// scroll uses is compiled there, not on the visitor's first scroll step.
void main() {
  BoldTextDraw draw({
    bool rehearsing = false,
    double progress = 0.5,
    double opacity = 1,
  }) => BoldTextComponent.drawFor(
    rehearsing: rehearsing,
    progress: progress,
    opacity: opacity,
  );

  test('on the rehearsal pass it makes its real draw, whatever the scroll', () {
    // At rest on the loading screen the scroll is at 0 and the text is
    // invisible: exactly when it would otherwise draw nothing.
    expect(
      draw(rehearsing: true, progress: 0, opacity: 0),
      BoldTextDraw.rehearsal,
    );
    expect(draw(rehearsing: true), BoldTextDraw.rehearsal);
  });

  test('otherwise nothing is drawn where the shader would draw nothing', () {
    expect(draw(progress: 0), BoldTextDraw.none);
    expect(draw(progress: 1), BoldTextDraw.none);
    expect(draw(opacity: 0), BoldTextDraw.none);
  });

  test('and the real draw is unchanged in between', () {
    expect(draw(progress: 0.5, opacity: 1), BoldTextDraw.full);
    expect(draw(progress: 0.01, opacity: 0.5), BoldTextDraw.full);
  });

  test('the one-pixel warm-up is gone: one mechanism', () {
    expect(BoldTextDraw.values.map((v) => v.name), isNot(contains('warmUp')));
  });
}
