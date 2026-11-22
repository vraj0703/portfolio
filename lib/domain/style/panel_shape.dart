/// The theme's panel shape, read by the Made with heart dialog and the
/// contact links' plate on a phone (one definition, not a copy each;
/// PORTFOLIO-29). Colours are [AppColors.panelSurface] and its pair.
abstract final class PanelShape {
  /// The dialog's corner radius.
  static const double radius = 4;

  /// A hairline edge, as the dialog has: the ground behind is the panel's
  /// own colour, so without it the panel has no outline.
  static const double borderWidth = 1;
}
