import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/material.dart';
import 'package:portfolio/domain/style/scene_palette.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';

/// Takes the contact screen's ground back, inside the engine that drew it.
///
/// A pass in the render loop rather than a widget laid over the game. The
/// difference is not tidiness: a `ColoredBox` in the Flutter tree can only
/// ever dim *everything* the game drew, because it has no way to reach in
/// between the layers. Here the dim is a layer like any other, so it sits
/// above the ground and the mark and below the affordance — the room goes
/// back and the thing being offered stays where it is.
///
/// That is also why the bouncy lines are not dimmed and the mark is: the
/// lines flank the menu and belong to it, and dimming half of one affordance
/// reads as a rendering fault rather than as emphasis.
class ContactDimComponent extends PositionComponent
    with FlameBlocListenable<SceneBloc, SceneState> {
  ContactDimComponent({required this.palette, super.priority});

  final ScenePalette palette;

  /// How long it takes to come up and go down.
  ///
  /// Matched to the arrival the corridor hands over through, so the room
  /// settling back and the black lifting are one movement rather than two.
  static const double fadeSeconds = 0.62;

  final Paint _paint = Paint();

  /// Whether the contact screen is the one on show.
  bool _isOn = false;

  /// How far the dim has come up, `0`..`1`.
  double _shown = 0;

  @visibleForTesting
  double get shown => _shown;

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
    _isOn = dimsFor(state);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void update(double dt) {
    super.update(dt);

    final target = _isOn ? 1.0 : 0.0;
    if (_shown == target) return;

    final step = dt / fadeSeconds;
    _shown = target > _shown
        ? (_shown + step).clamp(0.0, 1.0)
        : (_shown - step).clamp(0.0, 1.0);
  }

  @override
  void render(Canvas canvas) {
    if (_shown <= 0.001) return;

    // The palette's colour already carries how dark the dim goes; this only
    // scales it in and out, so the depth is decided in one place.
    final dim = palette.contactDim;
    _paint.color = dim.withValues(alpha: dim.a * _shown);

    canvas.drawRect(Offset.zero & size.toSize(), _paint);
  }
}
