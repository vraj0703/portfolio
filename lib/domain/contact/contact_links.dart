/// The addresses behind the contact menu.
///
/// Data rather than literals buried in whichever class does the launching, so
/// the profile can be swapped without touching the mechanism — and so the one
/// piece that is not built yet is a missing *value*, not a missing method.
class ContactProfile {
  const ContactProfile({
    required this.github,
    required this.linkedIn,
    required this.email,
    this.cv,
  });

  final Uri github;
  final Uri linkedIn;

  /// The address itself, not a `mailto:` — building the URI is the
  /// launcher's business, and the subject line belongs with it.
  final String email;

  /// Where the résumé is served from, once there is one.
  ///
  /// Null until the file exists. This is the whole of what is left to do for
  /// the CV: fill this in and the menu entry starts working, with no change
  /// to the interface, the implementation, or the screen. Deliberately not a
  /// method to be written later — a seam that needs code is a seam that gets
  /// forgotten, and one that needs a value announces itself.
  final Uri? cv;

  bool get hasCv => cv != null;

  static final ContactProfile vishal = ContactProfile(
    github: Uri.parse('https://github.com/vraj0703'),
    linkedIn: Uri.parse('https://www.linkedin.com/in/vraj0703/'),
    email: 'vraj0703@gmail.com',
  );
}

/// Anything the contact menu reaches for outside the scene.
///
/// The screen depends on this rather than on `url_launcher`, so the menu can
/// be exercised in a test without a platform channel underneath it, and so
/// the web build's idea of "download" can change without the screen knowing.
abstract class ContactLinks {
  Future<void> openGithub();

  Future<void> openLinkedIn();

  /// Hands off to whatever the visitor writes mail with.
  Future<void> composeEmail();

  /// Fetches the résumé. A no-op while [ContactProfile.cv] is unset.
  Future<void> downloadCv();
}
