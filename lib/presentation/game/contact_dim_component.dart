import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/material.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';

/// What a full-screen wash on the contact screen is for.
enum ContactWash {
  /// Takes the ground back, and stays for as long as the screen does.
  ///
  /// The contact screen is the logo screen a second time, and the second
  /// time it is not the subject — the menu is.
  dim,

  /// The dark the corridor handed over through, getting out of the way.
  ///
  /// Thrown up the moment the screen arrives and gone a breath later, so the
  /// ground comes up out of black rather than appearing on it.
  arrival,
}

/// A full-screen wash on the contact screen, inside the engine that drew it.
///
/// A pass in the render loop rather than a widget laid over the game, and the
/// difference is not tidiness: a `ColoredBox` in the Flutter tree can only
/// ever wash *everything* the game drew, because it has no way to reach in
/// between the layers. Here each wash is a layer like any other, and which
/// layers it covers is the whole of what it does.
///
/// The two sit on opposite sides of the mark, which is the point:
///
///  * [ContactWash.dim] goes above it, so the room stands back and the mark
///    with it. The bouncy lines stay above the dim, because they flank the
///    menu and belong to it — dimming half of one affordance reads as a
///    rendering fault rather than as emphasis.
///  * [ContactWash.arrival] goes below it, so the mark that flew in from the
///    corridor is not blinked out at the moment it arrives. It is the one
///    thing carried across the handover between two renderers, and painting
///    over it would defeat the point of carrying it.
class ContactDimComponent extends PositionComponent
    with FlameBlocListenable<SceneBloc, SceneState> {
  ContactDimComponent({
    required this.colour,
    required this.wash,
    super.priority,
  });

  /// What this pass paints, carrying its own depth in its alpha.
  final Color colour;

  final ContactWash wash;

  /// How long it takes to come up, or to get out of the way.
  ///
  /// One duration for both, so the room settling back and the black lifting
  /// are one movement rather than two.
  static const double fadeSeconds = 0.62;

  final Paint _paint = Paint();

  /// Whether the contact screen is the one on show.
  bool _isOn = false;

  /// How far this pass has come up, `0`..`1`.
  double _shown = 0;

  @visibleForTesting
  double get shown => _shown;

  /// Where the wash is heading.
  ///
  /// The dim follows the screen. The arrival is always on its way out — it
  /// is put back up by the screen *arriving*, not by the screen being there,
  /// which is the difference between a veil and a curtain.
  double get _target => switch (wash) {
    ContactWash.dim => _isOn ? 1 : 0,
    ContactWash.arrival => 0,
  };

  /// Whether [state] is one the room is stood back for.
  ///
  /// A predicate rather than an inline check, because it is the whole of the
  /// rule and the component around it cannot be built without a game loop.
  static bool dimsFor(SceneState state) => state is Contact;

  @override
  void onInitialState(SceneState state) {
    super.onInitialState(state);

    // Mounted straight into the contact screen — which happens on nothing
    // today, but every other layer in this scene has been caught out by
    // exactly that and each one was invisible until someone walked the route.
    _isOn = dimsFor(state);
    _shown = _isOn ? 1 : 0;
  }

  @override
  void onNewState(SceneState state) {
    super.onNewState(state);

    final wasOn = _isOn;
    _isOn = dimsFor(state);

    // Thrown up again on each arrival. Without this the veil would be spent
    // after the first visit and the second would appear on a lit screen
    // rather than coming up out of the dark the corridor left.
    if (wash == ContactWash.arrival && _isOn && !wasOn) _shown = 1;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void update(double dt) {
    super.update(dt);

    final target = _target;
    if (_shown == target) return;

    final step = dt / fadeSeconds;
    _shown = target > _shown
        ? (_shown + step).clamp(0.0, 1.0)
        : (_shown - step).clamp(0.0, 1.0);
  }

  @override
  void render(Canvas canvas) {
    if (_shown <= 0.001) return;

    // The colour already carries how dark the pass goes; this only scales it
    // in and out, so the depth is decided in one place.
    _paint.color = colour.withValues(alpha: colour.a * _shown);

    canvas.drawRect(Offset.zero & size.toSize(), _paint);
  }
}
