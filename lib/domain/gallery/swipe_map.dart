import 'dart:math' as math;

import 'package:vector_math/vector_math.dart';

/// What a swipe in the gallery means, from where the visitor is heading.
///
/// The path turns: down the corridor the visitor travels *into* the screen,
/// and along the testimonial wall they travel *across* it. A swipe along the
/// way they are travelling moves them, the room following the finger as a
/// page does; a swipe across it in the corridor brings the nearest frame on
/// that side into focus (Vishal, 2026-11-18: on the wall a sideways swipe
/// should move him, not an upward one).
enum SwipeIntent { none, travel, focusLeft, focusRight }

/// The axis travel runs along on screen, as a unit vector in screen terms:
/// `x` across the screen (right positive), `y` down it.
typedef ScreenAxis = ({double x, double y});

abstract final class SwipeMap {
  // -- The tuning, in one place. --------------------------------------------

  /// How far a finger goes, in logical pixels, before a swipe says what it
  /// is: past a tap's wobble.
  static const double minSwipe = 24;

  /// Scroll units per logical pixel of a travelling swipe: the old drag
  /// scroll's gain, so the room follows the finger at the same rate.
  static const double travelGain = 2;

  // -- The rules. -----------------------------------------------------------

  /// The screen axis that the visitor's [travel] (world, per step of the
  /// path) runs along, seen by a camera looking along [forward] (world).
  ///
  /// Travel along the line of sight is the screen's vertical (into the
  /// screen reads as up, as a page does); travel across it is horizontal.
  /// Heights are ignored: the path is walked, not climbed.
  static ScreenAxis travelAxis(Vector3 travel, Vector3 forward) {
    final f = Vector2(forward.x, forward.z);
    final t = Vector2(travel.x, travel.z);
    if (f.length2 == 0 || t.length2 == 0) return (x: 0, y: 1);
    f.normalize();
    // Right of the line of sight, on the floor plane.
    final right = Vector2(-f.y, f.x);
    final across = t.dot(right);
    final along = t.dot(f);
    final length = math.sqrt(across * across + along * along);
    return (x: across / length, y: along / length);
  }

  /// What a swipe of ([dx], [dy]) logical pixels means, with travel running
  /// along [axis] on screen.
  static SwipeIntent classify(double dx, double dy, ScreenAxis axis) {
    if (math.sqrt(dx * dx + dy * dy) < minSwipe) return SwipeIntent.none;
    final along = (dx * axis.x + dy * axis.y).abs();
    final across = (dx * axis.y - dy * axis.x).abs();
    if (along >= across) return SwipeIntent.travel;
    // Across the way of travel. Only a sideways swipe on a path running
    // into the screen picks a side; across a sideways path is up or down,
    // which has no side to pick.
    if (axis.y.abs() <= axis.x.abs()) return SwipeIntent.none;
    return dx > 0 ? SwipeIntent.focusRight : SwipeIntent.focusLeft;
  }

  /// How far onward a travelling swipe of ([dx], [dy]) moves the visitor, in
  /// scroll units: the room follows the finger, so a finger moving against
  /// the way of travel on screen carries the visitor forward.
  static double onward(double dx, double dy, ScreenAxis axis) =>
      -(dx * axis.x + dy * axis.y) * travelGain;
}
