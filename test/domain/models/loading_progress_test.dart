import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/models/loading_phase.dart';
import 'package:portfolio/domain/models/loading_progress.dart';

/// These are written generically over `LoadingPhase.values` on purpose.
/// The whole point of the design is that phases can be added later, so the
/// tests must keep meaning something when a second or third one appears
/// rather than needing to be rewritten alongside it.
void main() {
  final totalWeight =
      LoadingPhase.values.fold<double>(0, (sum, p) => sum + p.weight);

  group('LoadingProgress', () {
    test('starts empty and incomplete', () {
      expect(LoadingProgress.empty.value, 0);
      expect(LoadingProgress.empty.isComplete, isFalse);
    });

    test('every phase declares a positive weight', () {
      // A zero or negative weight would silently distort the whole bar.
      for (final phase in LoadingPhase.values) {
        expect(phase.weight, greaterThan(0), reason: phase.name);
      }
    });

    test('a completed phase contributes exactly its share of the total', () {
      for (final phase in LoadingPhase.values) {
        final progress = LoadingProgress.empty.advance(phase, 1);
        expect(
          progress.value,
          closeTo(phase.weight / totalWeight, 1e-9),
          reason: '${phase.name} should be worth its weight, normalised',
        );
      }
    });

    test('completing every phase lands exactly on 1.0', () {
      var progress = LoadingProgress.empty;
      for (final phase in LoadingPhase.values) {
        progress = progress.advance(phase, 1);
      }

      expect(progress.value, 1.0);
      expect(progress.isComplete, isTrue);
    });

    test('is incomplete while any single phase is outstanding', () {
      // Complete everything, then hold one phase back at 99%.
      for (final held in LoadingPhase.values) {
        var progress = LoadingProgress.empty;
        for (final phase in LoadingPhase.values) {
          progress = progress.advance(phase, phase == held ? 0.99 : 1.0);
        }

        expect(
          progress.isComplete,
          isFalse,
          reason: '${held.name} at 99% must still block the reveal',
        );
      }
    });

    test('reports the per-phase figure back', () {
      final phase = LoadingPhase.values.first;
      final progress = LoadingProgress.empty.advance(phase, 0.4);

      expect(progress.of(phase), closeTo(0.4, 1e-9));
    });

    test('unreported phases read as zero', () {
      expect(LoadingProgress.empty.of(LoadingPhase.values.first), 0);
    });

    test('clamps out-of-range reports', () {
      final phase = LoadingPhase.values.first;

      expect(LoadingProgress.empty.advance(phase, 5).of(phase), 1.0);
      expect(LoadingProgress.empty.advance(phase, -3).of(phase), 0.0);
    });

    test('never runs backwards', () {
      final phase = LoadingPhase.values.first;
      final peak = LoadingProgress.empty.advance(phase, 0.8);

      expect(peak.advance(phase, 0.2).of(phase), closeTo(0.8, 1e-9));
    });

    test('returns itself when a report changes nothing', () {
      // Lets the bloc skip a pointless emit by identity, not deep compare.
      final phase = LoadingPhase.values.first;
      final progress = LoadingProgress.empty.advance(phase, 0.5);

      expect(identical(progress.advance(phase, 0.5), progress), isTrue);
      expect(identical(progress.advance(phase, 0.1), progress), isTrue);
    });

    test('does not mutate the snapshot it advances from', () {
      final phase = LoadingPhase.values.first;
      final first = LoadingProgress.empty.advance(phase, 0.3);
      final second = first.advance(phase, 0.7);

      expect(first.of(phase), closeTo(0.3, 1e-9));
      expect(second.of(phase), closeTo(0.7, 1e-9));
    });

    test('compares by value so equal snapshots do not rebuild the UI', () {
      final phase = LoadingPhase.values.first;
      final a = LoadingProgress.empty.advance(phase, 0.6);
      final b = LoadingProgress.empty.advance(phase, 0.6);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(LoadingProgress.empty.advance(phase, 0.61))));
    });
  });

  group('the gallery shares the bar', () {
    test('is weighted above the game, because it takes longer', () {
      // A bar that races to half and then sits there while the slow half
      // finishes is worse than no bar.
      expect(
        LoadingPhase.gallery.weight,
        greaterThan(LoadingPhase.game.weight),
      );
    });

    test('the scene is not ready until both have reported', () {
      var progress = LoadingProgress.empty;
      progress = progress.advance(LoadingPhase.game, 1);

      expect(progress.isComplete, isFalse,
          reason: 'the gallery is still building');

      progress = progress.advance(LoadingPhase.gallery, 1);
      expect(progress.isComplete, isTrue);
    });

    test('finishing the light half moves the bar less than half way', () {
      final progress = LoadingProgress.empty.advance(LoadingPhase.game, 1);

      expect(progress.value, lessThan(0.5));
      expect(progress.value, greaterThan(0));
    });

    test('every declared phase counts toward the bar', () {
      // Adding a phase should widen the bar automatically; a phase that no
      // one waits on is a phase that can silently never finish.
      var progress = LoadingProgress.empty;
      for (final phase in LoadingPhase.values) {
        progress = progress.advance(phase, 1);
      }
      expect(progress.value, 1);
      expect(progress.isComplete, isTrue);
    });
  });
}
