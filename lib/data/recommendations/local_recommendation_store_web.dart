import 'package:portfolio/domain/gallery/testimonial_data.dart';
import 'package:web/web.dart' as web;

/// Keeps a pending recommendation in the browser's localStorage.
///
/// Only in the visitor's own browser: it is there so they see their words on
/// the wall straight away and on their next visit, not to collect anything.
/// Storage can be refused (private windows, blocked site data), and then the
/// words are simply held for this visit.
class LocalRecommendationStore implements RecommendationStore {
  static const String key = 'portfolio.pendingRecommendation';

  PendingRecommendation? _held;

  @override
  PendingRecommendation? load() {
    try {
      return PendingRecommendation.fromJson(
            web.window.localStorage.getItem(key),
          ) ??
          _held;
    } catch (_) {
      return _held;
    }
  }

  @override
  void save(PendingRecommendation recommendation) {
    _held = recommendation;
    try {
      web.window.localStorage.setItem(key, recommendation.toJson());
    } catch (_) {
      // Refused storage keeps it for this visit only.
    }
  }
}
