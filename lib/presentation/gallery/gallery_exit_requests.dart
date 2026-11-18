import 'package:flutter/foundation.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';

/// A request to leave the gallery from outside it: the drawer's bar.
///
/// The gallery is the one that leaves, because leaving is its own
/// lights-down fade and the scene event at the end of it; the drawer only
/// asks. Through this rather than the scene bloc, so both ways out (the wall
/// sign and the drawer) take the same fade.
class GalleryExitRequests extends ChangeNotifier {
  GalleryExitRequests._();

  /// The one channel: the gallery listens while it is mounted.
  static final GalleryExitRequests instance = GalleryExitRequests._();

  SceneEvent? _pending;

  /// Asks the gallery to leave for [event] (home: [SceneEvent.galleryExited];
  /// the contact page: [SceneEvent.contactRequested]) after its lights-down.
  void request([SceneEvent event = const SceneEvent.galleryExited()]) {
    _pending = event;
    notifyListeners();
  }

  /// The event asked for, taken once.
  SceneEvent? take() {
    final e = _pending;
    _pending = null;
    return e;
  }
}
