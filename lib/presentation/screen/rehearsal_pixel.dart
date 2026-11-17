import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:portfolio/presentation/screen/my_game.dart';

/// The title stage's real draws, made over the loading screen through one
/// physical pixel in the top-left corner.
///
/// Under the curtain they never reached the GPU (GL census on the ROG,
/// 2026-11-17), and offscreen they compile in another WebGL context than
/// the screen's. Drawn last, inside a rect clip (a scissor, which leaves the
/// program the same as the real draw's), they are the screen's own draws,
/// and they cost one pixel.
///
/// Stateful because it owns a [Ticker]: it repaints every frame while
/// mounted, which is only while the scene is loading.
class RehearsalPixel extends StatefulWidget {
  const RehearsalPixel({super.key});

  @override
  State<RehearsalPixel> createState() => _RehearsalPixelState();
}

class _RehearsalPixelState extends State<RehearsalPixel>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => _frame.value++)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _RehearsalPainter(
          repaint: _frame,
          pixel: 1 / View.of(context).devicePixelRatio,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _RehearsalPainter extends CustomPainter {
  _RehearsalPainter({required Listenable repaint, required this.pixel})
    : super(repaint: repaint);

  /// One physical pixel, in logical units.
  final double pixel;

  @override
  void paint(Canvas canvas, Size size) {
    final game = MyGame.stage.value;
    if (game == null) return;
    canvas
      ..save()
      ..clipRect(Rect.fromLTWH(0, 0, pixel, pixel));
    game.rehearseInto(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RehearsalPainter old) => old.pixel != pixel;
}
