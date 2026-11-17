/// How each kind of input moves the visitor down the corridor.
///
/// The scroll's progress runs from 0 at the entrance to 1 at the hall, so a
/// positive step walks forward. Wheel and finger have separate rules on
/// purpose: the wheel's sign is the desktop's long-standing choice, and a
/// finger must follow the hand, as it does on the title's scroll.
abstract final class GalleryInput {
  /// Which way a wheel turn walks the corridor.
  ///
  /// Inverted with respect to the stages before it, and deliberately so. Up
  /// to here the scroll has been moving a *page*: content travels up as the
  /// wheel goes down, which is what every scrolling surface does. The gallery
  /// is not a page — the visitor is walking through a room, and the natural
  /// reading of pushing the wheel away is moving away, deeper in.
  ///
  /// Keeping the page convention here would mean pushing forward to back out
  /// of the corridor, which fights the first-person framing the whole scene
  /// is built on.
  ///
  /// The wheel and the trackpad: a step against the event's `scrollDelta.dy`.
  /// Unchanged from before touch had its own rule.
  static const double wheelDirection = -1;

  /// How far a finger walks the corridor, against how far it travels.
  ///
  /// A wheel notch reports about a hundred units and a finger reports the
  /// pixels it crossed, so one-to-one makes the corridor several times longer
  /// to a thumb than to a mouse. Matched to the intro's own gain, so the two
  /// stages answer a swipe at the same rate.
  static const double dragGain = 2;

  /// The scroll step for a wheel or trackpad event of [scrollDeltaY].
  static double wheelStep(double scrollDeltaY) => scrollDeltaY * wheelDirection;

  /// The scroll step for a finger that moved [fingerDeltaY] on screen
  /// (negative is up). A swipe UP walks forward: the room follows the hand,
  /// the way the title's scroll already does. Before, this shared the
  /// wheel's sign and a swipe up walked the visitor backward.
  static double dragStep(double fingerDeltaY) => -fingerDeltaY * dragGain;
}
