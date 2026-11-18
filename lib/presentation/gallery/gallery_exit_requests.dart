import 'package:flutter/foundation.dart';

/// A request to leave the gallery from outside it: the drawer's entry.
///
/// The gallery is the one that leaves, because leaving is its own
/// lights-down fade and the scene event at the end of it; the drawer only
/// asks. Through this rather than the scene bloc, so both ways out (the wall
/// sign and the drawer) take the same fade.
class GalleryExitRequests extends ChangeNotifier {
  GalleryExitRequests._();

  /// The one channel: the gallery listens while it is mounted.
  static final GalleryExitRequests instance = GalleryExitRequests._();

  void request() => notifyListeners();
}
