import 'dart:math' as math;

import 'package:vector_math/vector_math.dart';

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
/// So the plane the artwork hangs on doubles as the case for the work: the
/// frame is a display, and focusing changes what it displays. That choice is
/// forced by the room. A gallery would put a card beside the piece, but the
/// frames stand five units apart and are four wide, leaving a one-unit gutter,
/// and the floor is only 0.8 below the frame's bottom edge. There is nowhere
/// in this corridor to hang a card that is big enough to read. The four square
/// metres already on the wall is the only surface with room on it.
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
  }) {
    final halfV = math.tan(fovY / 2);
    final forHeight = (height * margin / 2) / halfV;

    final halfH = math.tan(2 * math.atan(halfV * aspect) / 2);
    final forWidth = (width * margin / 2) / halfH;

    return math.max(math.max(forHeight, forWidth), minimumStandoff);
  }

  /// Where to stand to read [frame], in design space.
  ///
  /// The camera comes off the wall along its normal and looks straight back
  /// at the centre of the work — square on, not angled. A raking view of a
  /// flat plane of text is a view you cannot read.
  static FocusPose poseFor(Placement frame, {required double aspect}) {
    final distance = distanceFor(
      width: GalleryLayout.frameWidth,
      height: GalleryDimensions.frameMaxHeight,
      aspect: aspect,
    );

    // Frames hang just inside the wall they belong to, so the sign of their x
    // is also the direction of the wall — and stepping the *opposite* way is
    // stepping into the corridor rather than into the plaster.
    final inward = frame.position.x.isNegative ? 1.0 : -1.0;

    return FocusPose(
      position: Vector3(
        frame.position.x + inward * distance,
        frame.position.y,
        frame.position.z,
      ),
      target: Vector3(frame.position.x, frame.position.y, frame.position.z),
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
