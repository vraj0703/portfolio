import 'package:portfolio/domain/analytics/analytics.dart';

import 'posthog_stub.dart' if (dart.library.js_interop) 'posthog_web.dart';

export 'browser_stub.dart' if (dart.library.js_interop) 'browser_web.dart';

/// The project token, from `--dart-define=POSTHOG_TOKEN=…`, which CI fills
/// from a repository secret. Never written in a file.
const String posthogToken = String.fromEnvironment('POSTHOG_TOKEN');

/// Where the events go; PostHog's US cloud unless the build says otherwise.
const String posthogHost = String.fromEnvironment(
  'POSTHOG_HOST',
  defaultValue: 'https://us.i.posthog.com',
);

/// The analytics this build sends to: PostHog with a token, silence
/// without one. A build with no token sends nothing and loads nothing.
Analytics createAnalytics({String token = posthogToken}) => token.isEmpty
    ? SilentAnalytics()
    : PostHogAnalytics(token: token, host: posthogHost);

/// Loads the SDK, if this build has one. Called after the first frame.
void startAnalytics(Analytics analytics) {
  if (analytics is PostHogAnalytics) analytics.start();
}
