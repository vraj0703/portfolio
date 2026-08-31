import 'dart:js_interop';

import 'package:portfolio/data/radio/radio_stream.dart';
import 'package:web/web.dart' as web;

/// A live stream played by the browser's own audio element.
///
/// Deliberately not `audioplayers`, which every other sound in this app goes
/// through. Handed a SomaFM URL it fails outright with
/// `MEDIA_ELEMENT_ERROR: Format error (Code: 4)` — what it builds expects a
/// *file*, something with a length and an end, and a radio station is
/// neither.
class BrowserRadioStream implements RadioStream {
  BrowserRadioStream();

  /// What the stream is, for asking the browser whether it can play one.
  static const String mimeType = 'audio/mpeg';

  web.HTMLAudioElement? _element;

  @override
  Future<void> open(Uri url, {required double volume}) async {
    await close();

    // No `crossOrigin`. Setting it to "anonymous" turns an ordinary media
    // fetch into a CORS-gated one, and it is needed only to *read* the
    // samples — for a visualiser or an analyser node. This only plays them.
    final element = web.HTMLAudioElement()
      ..preload = 'auto'
      ..volume = volume
      ..src = url.toString();

    // In the document rather than floating loose. A detached element plays
    // in most browsers and it is not worth being one of the exceptions —
    // and hidden, because this is a radio, not a video.
    element.style.display = 'none';
    web.document.body?.append(element);

    _element = element;

    try {
      await element.play().toDart;
    } catch (_) {
      throw Exception(await _reason(element, url));
    }
  }

  /// What the element itself says went wrong.
  ///
  /// The rejected promise says only "it did not play". The element knows
  /// which of four quite different things happened, and they need different
  /// fixes — so unwrapping it is the difference between a log that ends the
  /// investigation and one that starts another round of guessing.
  static Future<String> _reason(web.HTMLAudioElement element, Uri url) async {
    // Asked first, because it settles the whole question on its own. An
    // empty answer means this browser has no MP3 decoder at all — which
    // Chromium builds without proprietary codecs genuinely do not, while the
    // Chrome beside them does. Nothing about the URL, the headers or the
    // element can be blamed for that, and no amount of tuning here fixes it.
    final support = element.canPlayType(mimeType);
    final codec = support.isEmpty
        ? 'this browser cannot play $mimeType at all'
        : 'browser reports $mimeType as "$support"';

    final error = element.error;
    final kind = error == null
        ? 'refused to play with no error set'
        : switch (error.code) {
            1 => 'the fetch was aborted',
            2 => 'the network dropped it',
            3 => 'the audio would not decode',
            4 => 'the source was refused (blocked, CORS, or not audio)',
            _ => 'unknown media error ${error.code}',
          };

    // The element's own message is usually empty, which is why the two
    // things either side of it are worth gathering.
    final said = error?.message ?? '';

    return '$kind${said.isEmpty ? '' : ' ($said)'} — $codec '
        '(networkState ${element.networkState}, src ${element.currentSrc}) '
        '— ${await _reach(url)}';
  }

  /// What the network says when the same URL is asked for directly.
  ///
  /// The element collapses every way of not getting a stream into one
  /// answer: a 403, a hostname that will not resolve, an extension blocking
  /// the host and a genuinely unplayable file all arrive as
  /// `MEDIA_ERR_SRC_NOT_SUPPORTED` with an empty message. That is a code 4
  /// meaning "format", reported for a problem that is nothing of the sort,
  /// and it sent this round in circles: the codec was confirmed playable
  /// while the request was never being answered at all.
  ///
  /// `fetch` reports HTTP honestly. A status here separates a working
  /// network from a blocked one in a single line, and that is the difference
  /// between a fix that belongs in this file and one that does not.
  static Future<String> _reach(Uri url) async {
    try {
      final response = await web.window.fetch(url.toString().toJS).toDart;

      // Cancelled, not read. Live radio has no end: left open, this would go
      // on pulling a stream down into an object nobody holds.
      response.body?.cancel().toDart.ignore();

      final type = response.headers.get('content-type') ?? '(no content type)';
      return 'a direct request answered HTTP ${response.status} $type';
    } catch (error) {
      return 'a direct request could not be made at all ($error) — '
          'something between this page and the host is refusing it, so the '
          'stream is not reaching the browser to be played';
    }
  }

  @override
  Future<void> close() async {
    final element = _element;
    _element = null;
    if (element == null) return;

    // Emptied as well as paused. A paused element holds its connection open
    // and goes on buffering audio nobody is listening to; clearing the source
    // and reloading is what actually lets go of it.
    element
      ..pause()
      ..src = ''
      ..load();
    element.remove();
  }

  @override
  Future<void> setVolume(double volume) async {
    _element?.volume = volume;
  }
}
