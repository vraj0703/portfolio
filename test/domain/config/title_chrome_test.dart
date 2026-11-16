import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/config/logo_config.dart';
import 'package:portfolio/domain/config/title_chrome.dart';
import 'package:portfolio/presentation/menu/title_actions.dart';

/// The title's header row on a phone, by Material's numbers.
void main() {
  const phone = Size(412, 915);
  const small = Size(360, 640);
  const laptop = Size(1440, 900);

  test('the numbers are Material\'s, on the 8 dp grid', () {
    expect(TitleChrome.icon, 24);
    expect(TitleChrome.target, 48);
    expect(TitleChrome.edge, 16);
    for (final v in <double>[
      TitleChrome.icon,
      TitleChrome.target,
      TitleChrome.edge,
      TitleChrome.gap,
      TitleChrome.markHeight,
    ]) {
      expect(v % TitleChrome.grid, 0, reason: '$v is off the grid');
    }
  });

  test('a phone is compact, a laptop is not', () {
    expect(TitleChrome.isCompact(phone), isTrue);
    expect(TitleChrome.isCompact(small), isTrue);
    expect(TitleChrome.isCompact(laptop), isFalse);
  });

  test(
    'on a phone the row is 24 in 48, 16 from the edges, clear of insets',
    () {
      final row = TitleActions.rowFor(phone, EdgeInsets.zero);
      expect(row.glyph, 24);
      expect(row.target, 48);
      expect(row.top, 16);
      expect(row.right, 16);

      final notched = TitleActions.rowFor(
        phone,
        const EdgeInsets.only(top: 30, right: 12),
      );
      expect(notched.top, 46);
      expect(notched.right, 28);
    },
  );

  test('the parked mark sits beside the row, on its middle line', () {
    final mark = TitleChrome.compactMarkRect(phone);
    expect(mark.left, closeTo(TitleChrome.edge, 1e-9));
    expect(mark.height, TitleChrome.markHeight);
    expect(mark.center.dy, TitleChrome.edge + TitleChrome.target / 2);
    expect(mark.width, closeTo(mark.height / LogoConfig.markAspect, 1e-9));
  });

  test('mark and three targets fit a 360-wide phone with room between', () {
    final mark = TitleChrome.compactMarkRect(small);
    const rowWidth = 3 * TitleChrome.target + 2 * TitleChrome.gap;
    final rowLeft = small.width - TitleChrome.edge - rowWidth;
    expect(rowLeft - mark.right, greaterThan(TitleChrome.target));
  });

  test('a laptop keeps the desktop rule exactly', () {
    final row = TitleActions.rowFor(laptop, EdgeInsets.zero);
    final glyph = TitleActions.glyphHeightFor(laptop);
    expect(row.glyph, glyph);
    expect(row.top, LogoConfig.exitMargin - (row.target - glyph) / 2);
  });
}
