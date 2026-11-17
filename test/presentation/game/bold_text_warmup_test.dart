import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/presentation/game/bold_text_component.dart';

/// The bold text's shader is compiled on the first frame, invisibly, not on
/// the visitor's first scroll step (a 420-460 ms frame in the phone trace).
void main() {
  BoldTextDraw draw({bool warmed = true, double progress = 0.5, double opacity = 1}) =>
      BoldTextComponent.drawFor(warmed: warmed, progress: progress, opacity: opacity);

  test('the first frame compiles the shader, whatever the scroll', () {
    // At rest on the loading screen the scroll is at 0 and the text is
    // invisible: exactly when the old code drew nothing, and so compiled
    // nothing.
    expect(draw(warmed: false, progress: 0, opacity: 0), BoldTextDraw.warmUp);
    expect(draw(warmed: false, progress: 0.5, opacity: 1), BoldTextDraw.warmUp);
  });

  test('after it, nothing is drawn where the shader would draw nothing', () {
    expect(draw(progress: 0), BoldTextDraw.none);
    expect(draw(progress: 1), BoldTextDraw.none);
    expect(draw(opacity: 0), BoldTextDraw.none);
  });

  test('and the real draw is unchanged in between', () {
    expect(draw(progress: 0.5, opacity: 1), BoldTextDraw.full);
    expect(draw(progress: 0.01, opacity: 0.5), BoldTextDraw.full);
  });
}
