import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/project_data.dart';
import 'package:portfolio/domain/gallery/skill_data.dart';
import 'package:portfolio/domain/gallery/testimonial_data.dart';

/// Parity tests for the data ported from the React gallery's `src/config/*.ts`.
///
/// A data port's failure mode is silent transcription drift — a dropped entry
/// or a reordered list changes the physical layout of the corridor (frame
/// positions and corridor length are derived from these counts) without
/// throwing anywhere. These assertions pin the shape against the TypeScript
/// source so drift fails loudly instead of rendering a subtly wrong gallery.
void main() {
  group('GalleryProjects', () {
    test('preserves the 7 projects in source order', () {
      expect(
        GalleryProjects.all.map((p) => p.id).toList(),
        <String>[
          'raj-sadan',
          'ai-mind',
          'ai-constitution',
          'ai-knowledge',
          'subwise',
          'jotter',
          'twin-health',
        ],
      );
    });

    test('splits walls on even/odd indices for the paired layout', () {
      // Left wall takes indices 0, 2, 4, 6; right wall takes 1, 3, 5. The
      // asymmetry is intentional — P7 sits alone on the left.
      expect(GalleryProjects.left.map((p) => p.id).toList(),
          <String>['raj-sadan', 'ai-constitution', 'subwise', 'twin-health']);
      expect(GalleryProjects.right.map((p) => p.id).toList(),
          <String>['ai-mind', 'ai-knowledge', 'jotter']);
    });

    test('every project carries the stats the frame canvas draws', () {
      for (final p in GalleryProjects.all) {
        expect(p.stats, isNotEmpty, reason: '${p.id} has no stats');
        expect(p.title, isNotEmpty, reason: '${p.id} has no title');
      }
    });
  });

  group('GalleryTestimonials', () {
    test('holds 7 entries, exactly one of which is the CTA', () {
      expect(GalleryTestimonials.all, hasLength(7));
      expect(GalleryTestimonials.all.where((t) => t.isCTA), hasLength(1));
    });

    test('the CTA sits last so it anchors the end of the wall pan', () {
      expect(GalleryTestimonials.all.last.isCTA, isTrue);
    });

    test('cards excludes the CTA', () {
      expect(GalleryTestimonials.cards, hasLength(6));
      expect(GalleryTestimonials.cards.any((t) => t.isCTA), isFalse);
    });

    test('every real testimonial has attribution', () {
      for (final t in GalleryTestimonials.cards) {
        expect(t.name, isNotEmpty, reason: '${t.id} has no name');
        expect(t.text, isNotEmpty, reason: '${t.id} has no text');
        expect(t.company, isNotEmpty, reason: '${t.id} has no company');
      }
    });
  });

  group('GallerySkills', () {
    test('keeps the 4-row keyboard layout', () {
      expect(GallerySkills.rows, hasLength(4));
      expect(GallerySkills.rows.map((r) => r.length).toList(),
          <int>[8, 7, 6, 5]);
    });

    test('flattens to 26 keycaps', () {
      expect(GallerySkills.all, hasLength(26));
    });

    test('assigns every skill a unique id', () {
      final ids = GallerySkills.all.map((s) => s.id).toSet();
      expect(ids, hasLength(GallerySkills.all.length));
    });
  });
}
