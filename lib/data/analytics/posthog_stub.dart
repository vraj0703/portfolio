import 'package:portfolio/domain/analytics/analytics.dart';

/// Off the web there is no browser SDK: the same silence as a build with no
/// token.
class PostHogAnalytics extends SilentAnalytics {
  PostHogAnalytics({required this.token, required this.host});

  final String token;
  final String host;

  void start() {}
}
