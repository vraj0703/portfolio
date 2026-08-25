import 'package:flutter/material.dart';

/// [AppColors] defines the contract for color schemes across the application.
/// Following the **Dependency Inversion Principle (DIP)**, the UI depends on this
/// abstraction rather than hardcoded color values.
abstract class AppColors {
  Color get loadingText;

  /// Backdrop the loading curtain paints over.
  Color get loadingBackdrop;

  /// Warm accent behind the mark — the aura and the exit burst.
  Color get loadingAccent;
}

/// [DefaultAppColors] provides the concrete color implementation for the portfolio.
/// It follows the **Single Responsibility Principle (SRP)** by only defining the
/// specific palette values.
class DefaultAppColors implements AppColors {
  const DefaultAppColors();

  @override
  Color get loadingText => const Color(0xFFFFFFFF);

  @override
  Color get loadingBackdrop => const Color(0xFF0A0A0C);

  @override
  Color get loadingAccent => const Color(0xFFC8A45C);
}

/// [AppColorsExtension] allows the custom color palette to be part of the Flutter [ThemeData].
/// This follows the **Open/Closed Principle (OCP)**, enabling theme extensions without
/// modifying the original theme classes.
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final AppColors colors;

  const AppColorsExtension({required this.colors});

  @override
  AppColorsExtension copyWith({AppColors? colors}) {
    return AppColorsExtension(colors: colors ?? this.colors);
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    // We don't typically lerp between entirely different color interfaces,
    // but individual colors within them could be lerped if needed.
    return t < 0.5 ? this : other;
  }
}

/// Extension on [BuildContext] for type-safe access to [AppColors].
/// This adheres to the **Interface Segregation Principle (ISP)** by providing
/// a clean, dedicated API for the UI layer.
extension ColorsX on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColorsExtension>()?.colors ??
      const DefaultAppColors();
}
