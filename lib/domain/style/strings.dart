import 'package:flutter/material.dart';

/// [AppStrings] defines the contract for localized or global strings across the application.
/// Following the **Dependency Inversion Principle (DIP)**, the UI layer depends on this
/// abstraction, making it easy to swap languages or update copy globally.
abstract class AppStrings {
  String get appTitle;
  String get tapToEnter;

  /// Formats the loading readout, e.g. "LOADING... 007%".
  String loadingProgress(double progress);
}

/// [DefaultAppStrings] provides the concrete string implementation for the portfolio.
/// It follows the **Single Responsibility Principle (SRP)** by only defining the
/// specific copy for the application.
class DefaultAppStrings implements AppStrings {
  const DefaultAppStrings();

  @override
  String get appTitle => 'Vishal Raj';

  @override
  String get tapToEnter => 'TAP TO ENTER';

  @override
  String loadingProgress(double progress) {
    final pct = (progress * 100).round().clamp(1, 100);
    return 'LOADING... ${pct.toString().padLeft(3, '0')}%';
  }
}

/// [AppStringsExtension] allows the custom string set to be part of the Flutter [ThemeData].
/// This follows the **Open/Closed Principle (OCP)**, enabling the theme to be extended
/// with new content without modifying the framework's theme classes.
class AppStringsExtension extends ThemeExtension<AppStringsExtension> {
  final AppStrings strings;

  const AppStringsExtension({required this.strings});

  @override
  AppStringsExtension copyWith({AppStrings? strings}) {
    return AppStringsExtension(strings: strings ?? this.strings);
  }

  @override
  AppStringsExtension lerp(
    ThemeExtension<AppStringsExtension>? other,
    double t,
  ) {
    if (other is! AppStringsExtension) return this;
    // Strings don't interpolate, so we switch at the midpoint.
    return t < 0.5 ? this : other;
  }
}

/// Extension on [BuildContext] for easy and type-safe access to [AppStrings].
/// This adheres to the **Interface Segregation Principle (ISP)** by providing
/// a dedicated API for strings.
extension StringsX on BuildContext {
  AppStrings get strings =>
      Theme.of(this).extension<AppStringsExtension>()?.strings ??
      const DefaultAppStrings();
}
