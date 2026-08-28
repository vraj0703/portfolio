import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/interfaces/queuer.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/screen/scene_input.dart';

class _Recorder implements Queuer {
  final events = <SceneEvent>[];

  @override
  void queue({required SceneEvent event}) => events.add(event);
}

void main() {
  late _Recorder recorder;

  Future<void> host(WidgetTester tester) {
    recorder = _Recorder();
    return tester.pumpWidget(
      MaterialApp(
        home: SceneInput(
          bloc: recorder,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  testWidgets('a tap asks the scene to advance', (tester) async {
    await host(tester);
    await tester.tapAt(const Offset(400, 300));

    expect(recorder.events, <SceneEvent>[const SceneEvent.tapped()]);
  });

  group('a key press does the same as a tap', () {
    for (final key in <LogicalKeyboardKey>[
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.numpadEnter,
      LogicalKeyboardKey.space,
    ]) {
      testWidgets(key.keyLabel, (tester) async {
        await host(tester);
        await tester.sendKeyEvent(key);

        expect(recorder.events, <SceneEvent>[const SceneEvent.tapped()]);
      });
    }
  });

  testWidgets('a key that means something else is left alone', (tester) async {
    // A scene that advances on *any* key can never use one for anything
    // else — and the arrows in particular already mean movement.
    await host(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);

    expect(recorder.events, isEmpty);
  });

  testWidgets('releasing a key does not advance a second time', (
    tester,
  ) async {
    // The handler is on key *down*. On key up it would fire again, and a
    // visitor who held the key would skip whatever came next.
    await host(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);

    expect(recorder.events, hasLength(1));
  });
}
