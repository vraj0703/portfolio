import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';

/// The finish every metal icon in the gallery wears.
///
/// One recipe, shared, because the entrance arrow and the three controls are
/// meant to read as the same object family — struck from the same metal by
/// the same hand.
///
/// Untextured, deliberately. A photographed metal was tried and taken off:
/// these are small objects, an arrow about a metre and the controls a third
/// of that, and a scanned grain at that size reads as noise rather than as a
/// surface. A plain metal is also honest about what the renderer can do here
/// — with no screen-space reflections, what sells metal in this room is the
/// shape of the highlight, and that comes from roughness rather than from a
/// photograph.
abstract final class IconMetal {
  /// Kept just bright enough that an icon is never wholly lost.
  ///
  /// Real metal in an unlit corner is black, and a control that disappears
  /// when the visitor happens to be standing in the wrong place has failed.
  /// Sheen, not a lamp.
  static final Vector4 sheen = Vector4(0.16, 0.11, 0.05, 1);

  /// Brass rather than steel, so the icons belong to a room lit this warm.
  static final Vector4 brass = Vector4(0.94, 0.71, 0.36, 1);

  static PhysicallyBasedMaterial of() => PhysicallyBasedMaterial()
    ..baseColorFactor = brass
    ..metallicFactor = 1
    // Not mirror-smooth. A polished shape shows a single pinpoint highlight
    // and reads as black everywhere else; roughening spreads it along the
    // form so the whole thing catches light.
    ..roughnessFactor = 0.28
    ..emissiveFactor = sheen;
}
