/// [RecommendationStore] in the visitor's own browser storage, or in memory
/// where there is none (tests, desktop).
library;

export 'local_recommendation_store_stub.dart'
    if (dart.library.js_interop) 'local_recommendation_store_web.dart';
