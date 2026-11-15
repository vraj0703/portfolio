import 'dart:math' as math;

import 'package:vector_math/vector_math.dart';

import 'control_layout.dart';
import 'gallery_dimensions.dart';
import 'gallery_layout.dart';

/// Where the camera stands to read one piece of work.
class FocusPose {
  const FocusPose({required this.position, required this.target});

  final Vector3 position;
  final Vector3 target;
}

/// Framing a single project, as opposed to walking past it.
///
/// The corridor gives the visitor a *poster*: a shape and a title, seen in
/// passing, enough to decide which one to stop at. Focusing has to earn that
/// stop by giving them something the corridor could not — otherwise clicking
/// buys nothing but scale, which is what the original did.
///
/// So the stop is a composition, not a crop: the piece and its wall label,
/// framed together. The label is small and set for this distance; down the
/// corridor only its name carries. The pieces are 2.4 wide and five apart,
/// which leaves the gutter a label needs.
///
/// Pure geometry, like the rest of `domain/gallery` — the interesting failure
/// is a framing that crops the work or puts the camera through a wall, and
/// neither is visible from inside a running scene.
abstract final class ProjectFocus {
  /// Breathing room around the work, as a multiple of its size.
  ///
  /// Framing a picture edge-to-edge reads as a crop rather than a
  /// composition, and leaves no margin for the aspect ratios where the fit is
  /// governed by the other axis.
  static const double margin = 1.18;

  /// How far the camera stops short of the wall, at minimum.
  ///
  /// A near plane clips whatever is closer than it, and a camera that fits
  /// the work by standing inside the frame shows nothing at all.
  static const double minimumStandoff = 1.2;

  /// Breathing room on a portrait screen, where the fit is the width.
  ///
  /// On a phone the shot is governed by width, and the same [margin] as a
  /// laptop stands the camera further off than it needs to, which makes a
  /// small label smaller. A portrait screen fits the composition edge to
  /// edge with a sliver either side.
  static const double portraitMargin = 1.04;

  /// The piece's paper inside its moulding.
  static double get cardWidth =>
      GalleryLayout.pieceWidth - GalleryLayout.pieceBorder * 2;

  /// The piece and its label side by side, edge to edge.
  static double get compositionWidth =>
      GalleryLayout.pieceWidth +
      GalleryLayout.labelGap +
      GalleryLayout.labelWidth;

  /// How far the composition's centre sits from the piece's, across the
  /// piece toward its label.
  static double get compositionShift =>
      GalleryLayout.labelSide *
      (GalleryLayout.labelGap + GalleryLayout.labelWidth) /
      2;

  /// Distance needed to fit [width] by [height] at [aspect].
  ///
  /// Both axes are checked and the larger distance wins. Checking only the
  /// height fits a tall viewport and crops the sides of a wide one, which is
  /// the failure nobody sees until it is on a laptop.
  static double distanceFor({
    required double width,
    required double height,
    required double aspect,
    double fovY = GalleryDimensions.fovRadians,
    double room = margin,
  }) {
    final halfV = math.tan(fovY / 2);
    final forHeight = (height * room / 2) / halfV;

    final halfH = math.tan(2 * math.atan(halfV * aspect) / 2);
    final forWidth = (width * room / 2) / halfH;

    return math.max(math.max(forHeight, forWidth), minimumStandoff);
  }

  /// How far the shot must reach below the work.
  ///
  /// The controls hang beneath the frame, so the framing has to take in both
  /// — a shot composed on the work alone crops them off the bottom of the
  /// screen, where they render perfectly and are seen by nobody. Derived from
  /// [ControlLayout] rather than restated, so moving the row cannot leave the
  /// camera framing where it used to be.
  static double get reachBelow =>
      ControlLayout.dropBelowFrame + ControlLayout.iconSize / 2;

  /// Where to stand to read [frame], in design space.
  ///
  /// The camera comes off the wall along its normal and looks straight back
  /// at the centre of the composition — square on, not angled. A raking view
  /// of a flat plane of text is a view you cannot read.
  static FocusPose poseFor(Placement frame, {required double aspect}) {
    final portrait = aspect < 1;
    final distance = distanceFor(
      width: compositionWidth,
      height: GalleryDimensions.frameMaxHeight + reachBelow,
      aspect: aspect,
      room: portrait ? portraitMargin : margin,
    );

    // Aimed low of the work's own centre by half what was added beneath it,
    // so the extra room appears where the controls are rather than as empty
    // ceiling above the frame; and across toward the label by half of it, so
    // the two sit in the middle of the shot together.
    final centre = frame.position +
        GalleryLayout.acrossOf(frame) * compositionShift
      ..y = frame.position.y - reachBelow / 2;

    // Frames hang just inside the wall they belong to, so the sign of their x
    // is also the direction of the wall — and stepping the *opposite* way is
    // stepping into the corridor rather than into the plaster.
    final inward = frame.position.x.isNegative ? 1.0 : -1.0;

    return FocusPose(
      position: Vector3(centre.x + inward * distance, centre.y, centre.z),
      target: centre,
    );
  }

  /// Whether a focus pose would put the camera through the far wall.
  ///
  /// Not a clamp, because clamping would silently crop the work instead. If
  /// this is ever true the room is too narrow for the framing and the fix is
  /// a wider corridor or a smaller frame, not a quietly worse shot.
  static bool fitsInside(FocusPose pose) =>
      pose.position.x.abs() < GalleryDimensions.wallX;
}
