import 'package:flutter/material.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/domain/style/strings.dart';
import 'package:portfolio/domain/style/text_styles.dart';

/// The theme values the Flame scene needs, resolved once at the widget layer.
///
/// Flame components sit outside the widget tree and have no [BuildContext],
/// so they cannot read `context.colors` the way a widget does. Rather than
/// hardcoding values back into the components — the thing the theme exists to
/// prevent — the scene is handed this snapshot when it is built.
///
/// It is a snapshot, not a live binding: a theme change after the game is
/// constructed will not reach it. That is fine while there is one theme, and
/// the fix when there isn't is to rebuild the game on theme change.
@immutable
class ScenePalette {
  const ScenePalette({
    required this.background,
    required this.overlayText,
    required this.overlayTextShadow,
    required this.lineGradient,
    required this.lineStops,
    required this.enterStyle,
    required this.tapToEnter,
    required this.primaryTitle,
    required this.secondaryTitle,
    required this.titlePrimaryStyle,
    required this.titleSecondaryStyle,
    required this.titleBase,
    required this.scrollCue,
    required this.boldText,
    required this.boldTextStyle,
  });

  /// Resolves the palette from the ambient theme.
  factory ScenePalette.of(BuildContext context) {
    final colors = context.colors;
    return ScenePalette(
      background: colors.sceneBackground,
      overlayText: colors.logoOverlayText,
      overlayTextShadow: colors.logoOverlayTextShadow,
      lineGradient: colors.logoLineGradient,
      lineStops: colors.logoLineStops,
      enterStyle: context.typography.enter.copyWith(
        color: colors.logoOverlayText,
      ),
      tapToEnter: context.strings.tapToEnter,
      primaryTitle: context.strings.primaryTitle,
      secondaryTitle: context.strings.secondaryTitle,
      titlePrimaryStyle: context.typography.titlePrimary,
      titleSecondaryStyle: context.typography.titleSecondary,
      titleBase: colors.titleBase,
      scrollCue: colors.scrollCue,
      boldText: context.strings.boldText,
      boldTextStyle: context.typography.boldText,
    );
  }

  /// The scene's ground, and the colour the mark is drawn in — the mark reads
  /// only because the god-ray pass gives it relief, so these must match.
  final Color background;

  final Color overlayText;
  final Color overlayTextShadow;

  final List<Color> lineGradient;
  final List<double> lineStops;

  final TextStyle enterStyle;

  final String tapToEnter;
  final String primaryTitle;
  final String secondaryTitle;

  final TextStyle titlePrimaryStyle;
  final TextStyle titleSecondaryStyle;

  /// Base tone the metallic shader modulates for the hero title.
  final Color titleBase;

  /// The downward arrow inviting the user onward.
  final Color scrollCue;

  /// The bold-text stage's line, and how it is set.
  final String boldText;
  final TextStyle boldTextStyle;


  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScenePalette &&
          background == other.background &&
          overlayText == other.overlayText &&
          overlayTextShadow == other.overlayTextShadow &&
          enterStyle == other.enterStyle &&
          tapToEnter == other.tapToEnter &&
          primaryTitle == other.primaryTitle &&
          secondaryTitle == other.secondaryTitle;

  @override
  int get hashCode => Object.hash(
    background,
    overlayText,
    overlayTextShadow,
    enterStyle,
    tapToEnter,
    primaryTitle,
    secondaryTitle,
  );
}
