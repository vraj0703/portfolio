export 'radio_stream_stub.dart'
    if (dart.library.js_interop) 'radio_stream_web.dart';

/// A live audio stream, opened and closed.
///
/// Thin on purpose. The radio needs four things from whatever is playing it —
/// open this URL, close it, set the level, and say when it fell over — and
/// wrapping exactly that is what lets the browser's own audio element do the
/// job on the web while a test on the Dart VM gets silence instead of a
/// compile error.
abstract class RadioStream {
  /// Opens [url] and starts playing.
  ///
  /// Completes when the stream is actually running. Throws if it will not
  /// open, which the player above turns into the radio reading `OFF`.
  Future<void> open(Uri url, {required double volume});

  /// Closes it, releasing the connection.
  Future<void> close();

  Future<void> setVolume(double volume);
}
