import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/utils/frame_watch.dart';

void main() {
  group('it stays quiet unless something is wrong', () {
    test('the first tick is never a stall', () {
      // It has nothing to measure against: the gap would be the time since
      // construction, which is not a frame. Counting it would put a stall at
      // the top of every log and send the next investigation after a ghost.
      final watch = FrameWatch(threshold: Duration.zero);
      watch.tick('first');

      expect(watch.slowFrames, 0);
    });

    test('and a fast frame is not worth mentioning', () {
      final watch = FrameWatch(threshold: const Duration(seconds: 1));
      for (var i = 0; i < 10; i++) {
        watch.tick('frame $i');
      }

      expect(watch.slowFrames, 0);
    });
  });

  group('and it cannot become the problem itself', () {
    test('it stops reporting once its budget is spent', () async {
      // This ships to the deployed site, because that is the only place the
      // fault shows. A watch that logged every slow frame forever would turn
      // one stutter into a console full of them — and then into a reason the
      // next frame is slow.
      final watch = FrameWatch(threshold: Duration.zero, budget: 3);

      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
        watch.tick('frame $i');
      }

      // Everything after the first is seen — the counting does not stop —
      // but only the budget is printed.
      expect(watch.slowFrames, greaterThan(3));
    });
  });
}
