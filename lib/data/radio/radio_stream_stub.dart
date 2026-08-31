import 'package:portfolio/data/radio/radio_stream.dart';

/// A radio that plays nothing, for everywhere that is not a browser.
///
/// The site is built for the web and the stream is an HTML audio element, so
/// this is what a test on the Dart VM gets — and what a desktop or mobile
/// build would get, silently, rather than failing to compile.
///
/// It reports success. A stub that threw would make every test that stands up
/// the app have to know the radio exists.
class BrowserRadioStream implements RadioStream {
  BrowserRadioStream();

  @override
  Future<void> open(Uri url, {required double volume}) async {}

  @override
  Future<void> close() async {}

  @override
  Future<void> setVolume(double volume) async {}
}
