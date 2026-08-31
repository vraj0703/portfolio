import 'package:flutter/material.dart';

/// [AppTypography] defines the contract for typography styles across the application.
/// Following the **Dependency Inversion Principle (DIP)**, the application should depend
/// on this abstraction rather than concrete implementations.
abstract class AppTypography {
  TextStyle get loading;

  /// The figure beside it, in a mono of its own.
  TextStyle get loadingReadout;

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
    letterSpacing: 6,
    color: loadingTextColor,
    fontFamily: 'Apertura',
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
    fontSize: 16,
    // No italic asked for. Margot ships regular and bold and nothing
    // sloped, so an italic here would be synthesised — the letterforms
    // sheared rather than redrawn, which on a face with any character of its
    // own reads as a rendering fault.
    fontFamily: 'Margot',
  );

  @override
  TextStyle get creditsHeading => const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.6,
    fontFamily: 'ModrntUrban',
  );

  @override
  TextStyle get creditsBody =>
      const TextStyle(fontSize: 14, height: 1.45, fontFamily: 'Chillax');

  @override
  TextStyle get creditsAction =>
      const TextStyle(fontSize: 14, letterSpacing: 1.2, fontFamily: 'Apertura');

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
    fontFamily: 'Margot',
  );

  @override
  TextStyle get titleSecondary => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 4,
    color: loadingTextColor,
    fontFamily: "Apertura",
  );

  @override
  TextStyle get wallName => const TextStyle(
    fontSize: 132,
    height: 1.2,
    letterSpacing: 10,
    fontWeight: FontWeight.w400,
    // A serif with real stress and a fine hairline, which is what lettering
    // cut into a building has always been set in. A geometric sans reads as
    // vinyl applied to the wall however it is shaded.
    fontFamily: 'ModrntUrban',
  );

  @override
  TextStyle get wallStatement => const TextStyle(
    fontSize: 52,
    height: 1.5,
    letterSpacing: 1.2,
    // The running text under the heading, at the family's regular weight —
    // the same face the one loud line is set in, which ties the wall's two
    // halves together where a second family would only add a voice.
    fontFamily: 'Margot',
  );

  @override
  TextStyle get wallSign => const TextStyle(
    fontSize: 104,
    height: 1.3,
    letterSpacing: 18,
    fontWeight: FontWeight.w400,
    fontFamily: 'Cunia',
  );

  /// The line telling the visitor how to handle the board.
  ///
  /// Smaller than a sign and tracked wide: it is an instruction, read once
  /// and then ignored, so it must be legible without competing with the
  /// board it is behind.
  @override
  TextStyle get wallInstruction => const TextStyle(
    fontSize: 56,
    height: 1.5,
    letterSpacing: 6,
    fontFamily: 'Cunia',
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
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: loadingTextColor,
    letterSpacing: 10,
    fontFamily: 'MonoLoading',
  );

  @override
  TextStyle get loadingReadout => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    color: loadingTextColor,
    // Tracked tighter than the label. The figure is three characters that
    // change every few frames, and at the label's spacing they read as three
    // separate things ticking rather than as one number counting.
    letterSpacing: 10,
    fontFamily: 'AzeretMono',
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
