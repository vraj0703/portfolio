import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/contact/contact_links.dart';

void main() {
  group('the address the e-mail entry hands off', () {
    // What `UrlContactLinks.composeEmail` builds. Pinned here rather than
    // exercised through the launcher, which needs a platform channel the
    // test has not got.
    Uri compose(String address, String subject) => Uri(
      scheme: 'mailto',
      path: address,
      query: 'subject=${Uri.encodeComponent(subject)}',
    );

    test('encodes the subject the way a mail client reads it', () {
      final uri = compose(
        ContactProfile.vishal.email,
        'Hello from your portfolio',
      );

      // `%20`, not `+`. This is the whole reason the query is built by hand
      // instead of through `queryParameters`, which is the obvious way to
      // write it and the wrong one: that encodes a space as `+`, which is a
      // form-encoding convention. A mail client reading a `mailto:` shows
      // the pluses, and the subject line arrives as
      // "Hello+from+your+portfolio".
      expect(uri.toString(), contains('%20'));
      expect(uri.toString(), isNot(contains('+')));
    });

    test('does not double-encode what it has already escaped', () {
      // The other half of the same worry: `Uri`'s own normalisation runs
      // over a string that is already escaped. It recognises a valid escape
      // and leaves it alone — if it did not, `%20` would come back as
      // `%2520` and the subject would arrive with the escapes visible.
      expect(compose('a@b.com', 'x y').toString(), endsWith('subject=x%20y'));
    });

    test('reaches the address on the profile', () {
      final uri = compose(ContactProfile.vishal.email, 'anything');
      expect(uri.scheme, 'mailto');
      expect(uri.path, ContactProfile.vishal.email);
    });
  });
}
