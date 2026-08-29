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

  /// Lettering painted on a gallery wall — the way out, and its like.
  TextStyle get wallSign;

  /// The glyphs on the gallery's navigation controls.
  TextStyle get galleryControl;
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

  /// Warm and slightly over-bright: this is lettering meant to read as lit
  /// rather than as printed, and it carries its own glow on the wall.
  static const Color wallInk = Color(0xFFFFE6B0);
  static const Color wallBody = Color(0xFFC4B496);

  @override
  TextStyle get wallName => const TextStyle(
    color: wallInk,
    fontSize: 132,
    height: 1.2,
    letterSpacing: 10,
    fontWeight: FontWeight.w300,
  );

  @override
  TextStyle get wallStatement => const TextStyle(
    color: wallBody,
    fontSize: 40,
    height: 1.5,
    letterSpacing: 1.2,
  );

  @override
  TextStyle get wallSign => const TextStyle(
    color: wallInk,
    fontSize: 104,
    height: 1.3,
    letterSpacing: 18,
    fontWeight: FontWeight.w400,
  );

  @override
  TextStyle get galleryControl => const TextStyle(
    fontSize: 26,
    height: 1,
    color: Color(0xFFF0E4CC),
    fontWeight: FontWeight.w300,
  );

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
