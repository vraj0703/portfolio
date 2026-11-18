/// Which of the title's buttons are shown, and how the gallery is walked on
/// a touch screen, as the feature flags say (`title_connect_button`,
/// `title_menu_button`, `gallery_walk_stick`; docs/analytics/README.md).
///
/// The compiled default is the present behaviour: both shown. A flag that is
/// absent, or PostHog being unreachable, leaves the default; the first paint
/// never waits for a flag.
class ButtonFlags {
  const ButtonFlags({
    this.connect = true,
    this.menu = true,
    this.walkStick = true,
  });

  final bool connect;
  final bool menu;

  /// Whether a touch screen walks the gallery with a thumb stick and looks
  /// around with a drag, rather than dragging the corridor like a page.
  /// Off, the old drag-scroll is the fallback, for comparing the two.
  final bool walkStick;

  @override
  bool operator ==(Object other) =>
      other is ButtonFlags &&
      other.connect == connect &&
      other.menu == menu &&
      other.walkStick == walkStick;

  @override
  int get hashCode => Object.hash(connect, menu, walkStick);

  @override
  String toString() =>
      'ButtonFlags(connect: $connect, menu: $menu, walkStick: $walkStick)';
}
