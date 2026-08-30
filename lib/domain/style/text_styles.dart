import 'package:flutter/material.dart';

/// [AppTypography] defines the contract for typography styles across the application.
/// Following the **Dependency Inversion Principle (DIP)**, the application should depend
/// on this abstraction rather than concrete implementations.
abstract class AppTypography {
  TextStyle get loading;

  /// "TAP TO ENTER". Widely tracked, so it reads as an instruction rather
  /// than a word.
  TextStyle get enter;

  /// The hero title. Its colour comes from the metallic shader rather than
  /// the style, so none is set here.
  TextStyle get titlePrimary;

  /// The line beneath the hero title.
  TextStyle get titleSecondary;

  /// The bold-text stage. Rasterised into a texture, so this is the only
  /// place its metrics are decided.
  TextStyle get boldText;

  /// The name on the gallery's far wall.
  TextStyle get wallName;

  /// The statement beneath it.
  TextStyle get wallStatement;

  /// Lettering cut into a gallery wall — the way out, and its like.
  TextStyle get wallSign;

  /// The instruction on the skills hall's far wall.
  TextStyle get wallInstruction;

  /// The glyphs on the gallery's navigation controls.
  TextStyle get galleryControl;

  /// The message shown when the gallery cannot be built.
  TextStyle get galleryFailure;

  /// The contact menu's destinations.
  ///
  /// Larger than [enter], and tracked far tighter. "TAP TO ENTER" is three
  /// words with the whole width to spread across; this is seven destinations
  /// and a row of separators, and the letterspacing that gives the
  /// affordance its poise pulls each word apart until the row reads as
  /// loose characters rather than as things to press.
  TextStyle get contactMenu;

  /// The credits: its title, the line under it, each heading, the things
  /// credited, and the way out.
  TextStyle get creditsTitle;
  TextStyle get creditsSubtitle;
  TextStyle get creditsHeading;
  TextStyle get creditsBody;
  TextStyle get creditsAction;
}

/// [DefaultAppTypography] is a concrete implementation of [AppTypography].
/// It follows the **Single Responsibility Principle (SRP)** by focusing solely on
/// providing the specific styling values for the application.
class DefaultAppTypography implements AppTypography {
  final Color loadingTextColor;
  final String? fontFamily;

  const DefaultAppTypography({
    this.loadingTextColor = Colors.black87,
    this.fontFamily,
  });

  @override
  TextStyle get enter => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    letterSpacing: 5,
    color: loadingTextColor,
    fontFamily: "Apertura",
  );

  @override
  TextStyle get contactMenu => const TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.4,
    fontFamily: 'Apertura',
  );

  @override
  TextStyle get creditsTitle => const TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    fontFamily: 'Apertura',
  );

  @override
  TextStyle get creditsSubtitle => const TextStyle(
    fontSize: 13,
    fontStyle: FontStyle.italic,
    fontFamily: 'Apertura',
  );

  @override
  TextStyle get creditsHeading => const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.6,
    fontFamily: 'Apertura',
  );

  @override
  TextStyle get creditsBody =>
      const TextStyle(fontSize: 14, height: 1.45, fontFamily: 'Apertura');

  @override
  TextStyle get creditsAction => const TextStyle(
    fontSize: 14,
    letterSpacing: 1.2,
    fontFamily: 'Apertura',
  );

  @override
  TextStyle get titlePrimary => const TextStyle(
    fontSize: 56,
    fontWeight: FontWeight.w500,
    letterSpacing: 28,
    fontFamily: "ModrntUrban",
  );

  @override
  @override
  TextStyle get boldText => TextStyle(
    fontSize: 64,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 1,
    // Near-white: the shader replaces the fill with brushed metal and only
    // reads the glyph's alpha, so the colour here is a mask, not a look.
    color: const Color(0xFFDDDDDD),
    fontFamily: "Apertura",
  );

  @override
  TextStyle get titleSecondary => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 4,
    color: loadingTextColor,
    fontFamily: "Apertura",
  );

  /// The two edges of a cut letter, and the stone between them.
  ///
  /// Lettering carved into a wall is not a colour on the wall — it is a
  /// groove, and what the eye reads is the pair of edges the groove makes.
  /// Light arrives from above, so the upper inside face of the cut is in
  /// shadow and the lower one catches it. Those two, plus the marble itself
  /// showing through the middle, are the whole effect.
  ///
  /// This replaced a warm cream that was painted *onto* the wall. It could
  /// not be made to read at any weight, and the reason is measurable rather
  /// than a matter of taste: the marble's own albedo is 0.875 and the ink
  /// was 0.908 — a contrast ratio of 1.04:1 where text wants 4.5:1 — and
  /// the wall is lit while the lettering, being unlit, is not. The wall
  /// finished brighter than the sign on it. A cut carries its own contrast
  /// wherever it is, because both edges move with the letter.
  static const Color wallCutShadow = Color(0xFF2A211A);
  static const Color wallCutLight = Color(0xFFFFF6E2);

  @override
  TextStyle get wallName => const TextStyle(
    fontSize: 132,
    height: 1.2,
    letterSpacing: 10,
    fontWeight: FontWeight.w400,
    // A serif with real stress and a fine hairline, which is what lettering
    // cut into a building has always been set in. A geometric sans reads as
    // vinyl applied to the wall however it is shaded.
    fontFamily: 'Marcellus',
  );

  @override
  TextStyle get wallStatement => const TextStyle(
    fontSize: 40,
    height: 1.5,
    letterSpacing: 1.2,
    // The running text under the heading, in a grotesque. Carving a serif
    // this small would lose the hairlines to the width of the cut.
    fontFamily: 'Satoshi',
  );

  @override
  TextStyle get wallSign => const TextStyle(
    fontSize: 104,
    height: 1.3,
    letterSpacing: 18,
    fontWeight: FontWeight.w400,
    fontFamily: 'Marcellus',
  );

  /// The line telling the visitor how to handle the board.
  ///
  /// Smaller than a sign and tracked wide: it is an instruction, read once
  /// and then ignored, so it must be legible without competing with the
  /// board it is behind.
  @override
  TextStyle get wallInstruction => const TextStyle(
    fontSize: 46,
    height: 1.5,
    letterSpacing: 6,
    fontFamily: 'Satoshi',
  );

  @override
  TextStyle get galleryControl => const TextStyle(
    fontSize: 26,
    height: 1,
    color: Color(0xFFF0E4CC),
    fontWeight: FontWeight.w300,
  );

  @override
  TextStyle get galleryFailure =>
      const TextStyle(color: Color(0xFFE8C97A), fontSize: 13);

  @override
  TextStyle get loading => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: loadingTextColor,
    letterSpacing: 10,
    fontFamily: "MonoLoading",
  );
}

/// [AppTypographyExtension] allows integrating custom typography into Flutter's [ThemeData].
/// This follows the **Open/Closed Principle (OCP)**, allowing the theme to be extended
/// with new properties without modifying the underlying Flutter framework classes.
class AppTypographyExtension extends ThemeExtension<AppTypographyExtension> {
  final AppTypography typography;

  const AppTypographyExtension({required this.typography});

  @override
  AppTypographyExtension copyWith({AppTypography? typography}) {
    return AppTypographyExtension(typography: typography ?? this.typography);
  }

  @override
  AppTypographyExtension lerp(
    ThemeExtension<AppTypographyExtension>? other,
    double t,
  ) {
    if (other is! AppTypographyExtension) return this;
    // Typography typically doesn't lerp smoothly, so we switch halfway.
    return t < 0.5 ? this : other;
  }
}

/// Extension on [BuildContext] to provide easy and type-safe access to [AppTypography].
/// This promotes cleaner code and adheres to the **Interface Segregation Principle (ISP)**
/// by providing only the typography-related interface to the UI.
extension TypographyX on BuildContext {
  AppTypography get typography =>
      Theme.of(this).extension<AppTypographyExtension>()?.typography ??
      const DefaultAppTypography();
}
