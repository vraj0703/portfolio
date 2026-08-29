import 'package:flutter/foundation.dart';
import 'package:portfolio/domain/contact/contact_links.dart';
import 'package:url_launcher/url_launcher.dart';

/// [ContactLinks] over the platform's own handlers.
///
/// Every destination goes out through the same one call, which is the reason
/// this class is as short as it is: the differences between a profile, a
/// mail client and a download are differences in the URI, not in the
/// mechanism.
class UrlContactLinks implements ContactLinks {
  const UrlContactLinks({required this.profile});

  final ContactProfile profile;

  /// Where a link opens.
  ///
  /// A new tab on the web, so the visitor does not lose the room they were
  /// standing in — walking back into the gallery through the browser's back
  /// button would reload the whole scene and drop them at the loading bar.
  static const LaunchMode mode = LaunchMode.externalApplication;

  @override
  Future<void> openGithub() => _open(profile.github);

  @override
  Future<void> openLinkedIn() => _open(profile.linkedIn);

  @override
  Future<void> composeEmail() => _open(
    Uri(
      scheme: 'mailto',
      path: profile.email,
      // A subject the recipient can filter on, and one the sender does not
      // have to invent before they have said anything.
      query: 'subject=${Uri.encodeComponent('Hello from your portfolio')}',
    ),
  );

  @override
  Future<void> downloadCv() async {
    final cv = profile.cv;

    // Nothing to fetch yet. Silent rather than throwing: the entry is on the
    // menu because it belongs there, and a visitor who presses it before the
    // file is published should meet a control that does nothing, not an
    // error about an unimplemented method.
    if (cv == null) return;
    await _open(cv);
  }

  Future<void> _open(Uri url) async {
    final opened = await launchUrl(url, mode: mode);

    // A blocked pop-up is the ordinary failure here and there is nothing to
    // be done about it from inside the page, so it is reported rather than
    // raised — the alternative is an exception crossing a tap handler.
    if (!opened) debugPrint('Could not open $url');
  }
}
