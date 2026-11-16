import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/data/recommendations/local_recommendation_store.dart';
import 'package:portfolio/domain/gallery/testimonial_data.dart';

void main() {
  const words = PendingRecommendation(
    name: ' Asha ',
    role: 'Lead, Acme',
    relationship: 'Managed Vishal',
    words: '  Calm under pressure.  ',
  );

  test('the clipboard carries the words alone, for LinkedIn to sign', () {
    expect(words.clipboardText, 'Calm under pressure.');
  });

  test('signs with name and role, or the name alone', () {
    expect(words.signature, 'Asha, Lead, Acme');
    const bare = PendingRecommendation(
      name: 'Asha',
      role: '',
      relationship: '',
      words: 'x',
    );
    expect(bare.signature, 'Asha');
  });

  test('round-trips through browser storage', () {
    final back = PendingRecommendation.fromJson(words.toJson())!;
    expect(back.name, words.name);
    expect(back.role, words.role);
    expect(back.relationship, words.relationship);
    expect(back.words, words.words);
  });

  test('anything in storage that is not one of ours is ignored', () {
    // Browser storage is the visitor's and can hold anything; a bad entry
    // must not put a broken card on the wall.
    for (final raw in <String?>[
      null,
      '',
      'not json',
      '[]',
      '{"name": "", "words": "x"}',
      '{"name": "x"}',
    ]) {
      expect(PendingRecommendation.fromJson(raw), isNull, reason: '$raw');
    }
  });

  test('the store keeps what it was given', () {
    final store = LocalRecommendationStore();
    expect(store.load(), isNull);
    store.save(words);
    expect(store.load()?.words, words.words);
  });
}
