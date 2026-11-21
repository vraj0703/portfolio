import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/config/title_contrast.dart';
import 'package:portfolio/domain/config/title_timeline.dart';

NameBand _band({
  double presence = 1,
  double x = 640,
  double y = 360,
  double halfWidth = 300,
}) => NameBand(
  presence: presence,
  centreXPx: x,
  centreYPx: y,
  halfWidthPx: halfWidth,
);

void main() {
  const e = TitleContrast.warmBand;

  group('the dimming behind the name arrives with the name (PORTFOLIO-22)', () {
    test('none while the name is absent, for every way', () {
      // Vishal, 2026-11-21: the dimming showed before the name, as a dark
      // shape of its own in the sky.
      for (final way in TitleContrast.values) {
        expect(
          TitleContrastConfig.strengthFor(way, NameBand.absent),
          0,
          reason: '$way',
        );
      }
    });

    test('full only with the name at rest, and in step with it between', () {
      final full = TitleContrastConfig.dimFor(e);
      expect(full, greaterThan(0));
      expect(TitleContrastConfig.strengthFor(e, _band()), full);
      expect(
        TitleContrastConfig.strengthFor(e, _band(presence: 0.25)),
        closeTo(full * 0.25, 1e-9),
      );
      expect(TitleContrastConfig.strengthFor(e, _band(presence: 3)), full);
    });

    test('through the entrance, as far as the name has faded in', () {
      final full = TitleContrastConfig.dimFor(e);
      double at(double t) => TitleContrastConfig.strengthFor(
        e,
        _band(presence: TitleTimeline.primaryFade(t)),
      );
      // The stage's opening pause: backdrop up, name not yet there.
      expect(at(0), 0);
      expect(at(TitleTimeline.primaryStart), 0);
      final mid = (TitleTimeline.primaryStart + TitleTimeline.primaryEnd) / 2;
      expect(at(mid), inExclusiveRange(0, full));
      expect(at(TitleTimeline.primaryEnd), full);
    });

    test('and leaves with it: the exit fade is the name\'s fade', () {
      final full = TitleContrastConfig.dimFor(e);
      const stageFade = 0.4; // part way up the scroll to the bold text
      expect(
        TitleContrastConfig.strengthFor(
          e,
          _band(
            presence:
                TitleTimeline.primaryFade(TitleTimeline.primaryEnd) * stageFade,
          ),
        ),
        closeTo(full * stageFade, 1e-9),
      );
    });
  });

  group('the band is the name\'s size and place', () {
    test('(E) is as wide as the name is drawn, with no wide fallback', () {
      // A name at scale zero used to fall back to the 0.75-wide ellipse,
      // then snap to a narrow box as it began to grow.
      final none = TitleContrastConfig.halfWidthFor(
        e,
        _band(halfWidth: 0),
        720,
      );
      expect(none, closeTo(TitleContrastConfig.warmMargin, 1e-9));
      final small = TitleContrastConfig.halfWidthFor(
        e,
        _band(halfWidth: 72),
        720,
      );
      final big = TitleContrastConfig.halfWidthFor(
        e,
        _band(halfWidth: 360),
        720,
      );
      expect(small, closeTo(0.1 + TitleContrastConfig.warmMargin, 1e-9));
      expect(big, closeTo(0.5 + TitleContrastConfig.warmMargin, 1e-9));
    });

    test('centred on the name, in the backdrop\'s uv (up positive)', () {
      expect(TitleContrastConfig.centreFor(_band(), 1280, 720), (0.0, 0.0));
      final (x, y) = TitleContrastConfig.centreFor(
        _band(x: 640 + 72, y: 360 - 36),
        1280,
        720,
      );
      expect(x, closeTo(0.1, 1e-9));
      expect(y, closeTo(0.05, 1e-9));
    });
  });

  group('one source of truth', () {
    test('the backdrop reads the name, and keeps no dimming of its own', () {
      final backdrop = File(
        'lib/presentation/game/backdrop_component.dart',
      ).readAsStringSync();
      expect(backdrop, contains('strengthFor(way, nameBand)'));
      expect(backdrop, isNot(contains('dimFor(')));
      final game = File(
        'lib/presentation/screen/my_game.dart',
      ).readAsStringSync();
      expect(game, contains('_backdrop.nameBand = _title.nameBand;'));
      final title = File(
        'lib/presentation/game/title_layer_component.dart',
      ).readAsStringSync();
      // The presence is the fade the glyphs are drawn with.
      expect(title, contains('presence: _primary.fade'));
    });
  });
}
