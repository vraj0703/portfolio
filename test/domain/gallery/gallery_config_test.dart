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
    test('holds the seven frames in wall order', () {
      expect(GalleryProjects.all.map((p) => p.id).toList(), <String>[
        'shunya-systems',
        'twin-health',
        'tantr',
        'fieldassist-payu',
        'publications',
        'school-college',
        'creative-works',
      ]);
    });

    test('splits walls on even/odd indices for the paired layout', () {
      // Left wall takes indices 0, 2, 4, 6; right wall takes 1, 3, 5. The
      // asymmetry is intentional — P7 sits alone on the left.
      // Left is what Vishal builds now, right is where he built before.
      expect(GalleryProjects.left.map((p) => p.id).toList(), <String>[
        'shunya-systems',
        'tantr',
        'publications',
        'creative-works',
      ]);
      expect(GalleryProjects.right.map((p) => p.id).toList(), <String>[
        'twin-health',
        'fieldassist-payu',
        'school-college',
      ]);
    });

    test('every finished project carries the stats its card draws', () {
      // A `soon` frame shows its title and "coming soon" only.
      for (final p in GalleryProjects.all) {
        expect(p.title, isNotEmpty, reason: '${p.id} has no title');
        if (p.isLive) {
          expect(p.stats, isNotEmpty, reason: '${p.id} has no stats');
        }
      }
    });

    test('no TODO marker reaches anything a card renders', () {
      // TODOs live in comments and the PR's gap list. On the wall, an
      // unknown is left out, not announced.
      for (final p in GalleryProjects.all) {
        final shown = <String>[
          p.title,
          p.description,
          p.summary,
          ...p.stats,
          ...p.stack,
        ];
        for (final text in shown) {
          expect(text, isNot(contains('TODO')), reason: p.id);
        }
      }
    });
  });

  group('TestimonialWall', () {
    test('five frames: the invitation, then reserved ones', () {
      expect(TestimonialWall.slots, 5);
      expect(TestimonialWall.slotFor(0), TestimonialSlot.invitation);
      for (var i = 1; i < TestimonialWall.slots; i++) {
        expect(TestimonialWall.slotFor(i), TestimonialSlot.reserved);
      }
    });

    test("a visitor's own words take frame 2, and only frame 2", () {
      const mine = PendingRecommendation(
        name: 'A',
        role: 'B',
        relationship: 'C',
        words: 'D',
      );
      expect(
        TestimonialWall.slotFor(1, pending: mine),
        TestimonialSlot.pending,
      );
      expect(
        TestimonialWall.slotFor(2, pending: mine),
        TestimonialSlot.reserved,
      );
    });
  });

  group('GallerySkills', () {
    test('keeps the 4-row keyboard layout', () {
      expect(GallerySkills.rows, hasLength(4));
      expect(GallerySkills.rows.map((r) => r.length).toList(), <int>[
        8,
        7,
        6,
        5,
      ]);
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
