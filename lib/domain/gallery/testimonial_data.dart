import 'dart:convert';

/// The testimonial wall.
///
/// Five frames on the far wall of the wing. The six testimonials carried
/// over from the React site are gone: they were invented names and words,
/// and a gallery that hangs quotes nobody said is worse than one with empty
/// frames. Until real recommendations are approved, the wall is:
///
/// - frame 1, [invitation]: the title and an invitation to add yours;
/// - frames 2 to 5: a quiet "reserved" card, no fake quote;
/// - except that a visitor who has just written a recommendation sees their
///   own words in frame 2, [pendingSlot], marked pending — on their own
///   machine only, kept in the browser, never sent anywhere.
abstract final class TestimonialWall {
  /// How many frames hang on the wall; see `GalleryDimensions`.
  static const int slots = 5;

  /// The frame that invites a recommendation.
  static const int invitation = 0;

  /// The frame that shows a visitor's own pending words.
  static const int pendingSlot = 1;

  /// What [slot] shows, given the visitor's own [pending] words if any.
  static TestimonialSlot slotFor(int slot, {PendingRecommendation? pending}) {
    if (slot == invitation) return TestimonialSlot.invitation;
    if (slot == pendingSlot && pending != null) return TestimonialSlot.pending;
    return TestimonialSlot.reserved;
  }
}

/// What a testimonial frame shows.
enum TestimonialSlot { invitation, reserved, pending }

/// A recommendation a visitor wrote here and is taking to LinkedIn.
///
/// Nothing is sent from the site: the words are copied for the visitor to
/// paste into LinkedIn's own recommendation form, and kept in their browser
/// so they see them on the wall straight away, marked pending.
class PendingRecommendation {
  const PendingRecommendation({
    required this.name,
    required this.role,
    required this.relationship,
    required this.words,
  });

  final String name;

  /// Their role and company, as they would sign it.
  final String role;

  /// How they know Vishal: managed him, worked with him, and so on.
  final String relationship;

  final String words;

  /// What is copied for LinkedIn: the words alone. LinkedIn already knows who
  /// is writing and asks for the relationship itself, so anything more would
  /// have to be deleted again before posting.
  String get clipboardText => words.trim();

  /// The sign-off under the words on the wall.
  String get signature =>
      role.trim().isEmpty ? name.trim() : '${name.trim()}, ${role.trim()}';

  String toJson() => jsonEncode(<String, String>{
    'name': name,
    'role': role,
    'relationship': relationship,
    'words': words,
  });

  /// Null for anything that is not a recommendation this site wrote: browser
  /// storage is the visitor's, and can hold anything.
  static PendingRecommendation? fromJson(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map<String, dynamic>) return null;
      final name = map['name'];
      final words = map['words'];
      if (name is! String || words is! String) return null;
      if (name.trim().isEmpty || words.trim().isEmpty) return null;
      return PendingRecommendation(
        name: name,
        role: map['role'] is String ? map['role'] as String : '',
        relationship: map['relationship'] is String
            ? map['relationship'] as String
            : '',
        words: words,
      );
    } on FormatException {
      return null;
    }
  }
}

/// Where a visitor's pending recommendation is kept between visits.
abstract class RecommendationStore {
  PendingRecommendation? load();

  void save(PendingRecommendation recommendation);
}
