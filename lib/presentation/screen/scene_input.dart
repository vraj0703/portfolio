import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portfolio/domain/interfaces/queuer.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';

/// Ways into the scene that do not depend on the game loop.
///
/// The scene already takes taps through Flame, and this does not replace
/// that. It sits above it because the two are not equally reliable: Flame
/// wires its tap recognizer when the dispatcher component mounts, which is
/// after [GameWidget] has already built its gesture detector, so the entry
/// tap is subject to a lifecycle race. A pointer listener at the widget layer
/// has no such ordering — it is attached the moment the widget is.
///
/// It is the one path a tap takes to the bloc. Flame's tap handler used to
/// raise it as well, which was harmless while any tap entered; since a
/// touch's first tap shows the logo's hover and its second enters
/// (PORTFOLIO-27), one finger raising it twice entered at once.
///
/// A [Listener] rather than a [GestureDetector], deliberately. A gesture
/// detector competes in the arena, and winning there would take the tap
/// *away* from Flame — breaking the scroll cue's own tap handling. A raw
/// pointer listener observes without competing.
class SceneInput extends StatelessWidget {
  const SceneInput({required this.bloc, required this.child, super.key});

  final Queuer bloc;
  final Widget child;

  /// Keys that mean "go on".
  ///
  /// Enter because the affordance reads "TAP TO ENTER", and space because it
  /// is what a visitor presses when a page is waiting for them. Escape and
  /// the arrows are deliberately absent: they mean other things elsewhere,
  /// and a scene that advances on any key at all cannot later use one.
  /// Not `const`: [LogicalKeyboardKey] defines its own equality, which a
  /// constant set is not allowed to depend on.
  static final Set<LogicalKeyboardKey> advanceKeys = <LogicalKeyboardKey>{
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.space,
  };

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) {
        // Down, not up: a key held at the title should not fire again when it
        // is finally released. `KeyDownEvent` excludes auto-repeat too.
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (!advanceKeys.contains(event.logicalKey)) {
          return KeyEventResult.ignored;
        }

        bloc.queue(event: const SceneEvent.tapped());
        return KeyEventResult.handled;
      },
      child: Listener(
        // Whether it is a touch's: asked as "not a mouse", since some touch
        // reaches Flutter web with an unknown kind (CDP, adb).
        onPointerDown: (e) => bloc.queue(
          event: SceneEvent.tapped(
            touch:
                e.kind != PointerDeviceKind.mouse &&
                e.kind != PointerDeviceKind.trackpad,
          ),
        ),
        // A listener defers to its child by default, and a child that takes
        // no part in hit testing — anything the scene shows before the game
        // is up — leaves it receiving nothing at all.
        behavior: HitTestBehavior.opaque,
        child: child,
      ),
    );
  }
}
