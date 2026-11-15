/// Which of the title's buttons are shown, as the feature flags say
/// (`title_connect_button`, `title_menu_button`; docs/analytics/README.md).
///
/// The compiled default is the present behaviour: both shown. A flag that is
/// absent, or PostHog being unreachable, leaves the default; the first paint
/// never waits for a flag.
class ButtonFlags {
  const ButtonFlags({this.connect = true, this.menu = true});

  final bool connect;
  final bool menu;

  @override
  bool operator ==(Object other) =>
      other is ButtonFlags && other.connect == connect && other.menu == menu;

  @override
  int get hashCode => Object.hash(connect, menu);

  @override
  String toString() => 'ButtonFlags(connect: $connect, menu: $menu)';
}
