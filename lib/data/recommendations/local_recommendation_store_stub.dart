import 'package:portfolio/domain/gallery/testimonial_data.dart';

/// Keeps a pending recommendation for the life of the app only.
///
/// What a test and a desktop build get: there is no browser storage to keep
/// it in between visits, and nothing here may leave the machine.
class LocalRecommendationStore implements RecommendationStore {
  PendingRecommendation? _held;

  @override
  PendingRecommendation? load() => _held;

  @override
  void save(PendingRecommendation recommendation) => _held = recommendation;
}
