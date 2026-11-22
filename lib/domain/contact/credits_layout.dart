/// How the "Made with heart" dialog sits on a screen of a given shape
/// (PORTFOLIO-31, Vishal: "the dialog looks thin, and we need to take care
/// of the resolution too for phone").
class CreditsLayoutSpec {
  const CreditsLayoutSpec({
    required this.width,
    required this.maxHeight,
    required this.insetLeft,
    required this.insetRight,
    required this.insetTop,
    required this.insetBottom,
    required this.paddingH,
    required this.columns,
  });

  /// The panel's width, logical px.
  final double width;

  /// The panel's height at most: its body scrolls inside, the title and the
  /// close icon stay put.
  final double maxHeight;

  /// From the screen's edges to the panel (the safe area included).
  final double insetLeft;
  final double insetRight;
  final double insetTop;
  final double insetBottom;

  /// The panel's own side padding.
  final double paddingH;

  /// The credit groups in one column, or two on a wide desktop.
  final int columns;
}

/// The width rule: from the screen's shape, not a constant in the widget.
abstract final class CreditsLayout {
  /// Below this width a screen is a phone's; from [desktopFrom] a desktop's;
  /// between, a tablet's (a phone held sideways falls there too).
  static const double phoneBelow = 600;
  static const double desktopFrom = 1024;

  /// Two columns only from here, and only when asked for.
  static const double twoColumnsFrom = 1280;

  /// A desktop's reading measure: lines of about 60 to 75 characters at the
  /// body's size. A tablet's, a little narrower; two columns, two measures.
  static const double desktopWidth = 600;
  static const double tabletWidth = 560;
  static const double twoColumnWidth = 920;

  /// A phone: nearly the full width, 16 dp clear of each edge, more on a
  /// tablet; and clear of the top and bottom.
  static const double phoneMargin = 16;
  static const double tabletMargin = 48;
  static const double verticalMargin = 16;

  /// The panel at most this share of the screen's height.
  static const double heightShare = 0.85;

  /// The panel's side padding: a phone's narrower.
  static const double paddingH = 28;
  static const double phonePaddingH = 20;

  /// A tap target's least size (Material's 48 dp): "write to me".
  static const double linkTarget = 48;

  /// `?pc-credits=2` shows the groups in two columns on a wide desktop, to
  /// compare (one column ships).
  static final int columnsInUse = Uri.base.queryParameters['pc-credits'] == '2'
      ? 2
      : 1;

  /// The dialog on a [width] x [height] screen whose safe area takes
  /// [safeLeft], [safeRight], [safeTop] and [safeBottom] from its edges.
  static CreditsLayoutSpec forScreen(
    double width,
    double height, {
    double safeLeft = 0,
    double safeRight = 0,
    double safeTop = 0,
    double safeBottom = 0,
    int? columns,
  }) {
    final phone = width < phoneBelow;
    final margin = phone ? phoneMargin : tabletMargin;
    final room = width - safeLeft - safeRight - 2 * margin;
    final wanted = (columns ?? columnsInUse) == 2 && width >= twoColumnsFrom;
    final measure = phone
        ? room
        : wanted
        ? twoColumnWidth
        : width >= desktopFrom
        ? desktopWidth
        : tabletWidth;
    final panel = measure < room ? measure : room;
    return CreditsLayoutSpec(
      width: panel,
      maxHeight: (height - safeTop - safeBottom) * heightShare,
      // The room the panel is centred in: never closer to an edge than its
      // margin and the safe area on that side.
      insetLeft: safeLeft + margin,
      insetRight: safeRight + margin,
      insetTop: safeTop + verticalMargin,
      insetBottom: safeBottom + verticalMargin,
      paddingH: phone ? phonePaddingH : paddingH,
      columns: wanted ? 2 : 1,
    );
  }
}
