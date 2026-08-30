import 'package:flutter/material.dart';
import 'package:portfolio/domain/contact/contact_menu.dart';

/// [AppStrings] defines the contract for localized or global strings across the application.
/// Following the **Dependency Inversion Principle (DIP)**, the UI layer depends on this
/// abstraction, making it easy to swap languages or update copy globally.
abstract class AppStrings {
  String get appTitle;
  String get tapToEnter;

  /// The hero title and the line beneath it.
  String get primaryTitle;
  String get secondaryTitle;

  /// The bold-text stage's line.
  String get boldText;

  /// The two signs cut into the gallery's marble.
  String get galleryBack;
  String get letsConnect;

  /// How to handle the skills board, cut into the wall behind it.
  String get keyboardInstruction;

  /// The contact menu, in the order [ContactMenu] reads.
  String get contactCv;
  String get contactEmail;
  String get contactGithub;
  String get contactLinkedIn;

  /// Reads with the heart drawn after it, in the menu and again as the
  /// credits' own title — one string, because they are the same words
  /// saying the same thing in two places.
  String get madeWith;

  /// The credits dialog, opened by the heart.
  String get creditsSubtitle;
  String get creditsClose;

  /// What each mark on the menu is, for anyone who cannot see it.
  String contactMarkLabel(ContactDestination destination);

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
  String get primaryTitle => 'VISHAL RAJ';

  @override
  String get secondaryTitle => 'Welcome to my space';

  @override
  String get boldText => 'Crafting Clarity from Chaos.';

  @override
  String get galleryBack => 'BACK';

  @override
  String get letsConnect => "LET'S CONNECT";

  @override
  // Two gestures and nothing else. The visitor has arrived at the end of a
  // long walk and is looking at the board, not reading a manual — anything
  // longer than a line goes unread, and a line that has to be studied is
  // worse than no line, because it takes the attention the board wants.
  String get keyboardInstruction => 'DRAG TO TURN   ·   CLICK A KEY';

  @override
  String get contactCv => 'cv';

  @override
  String get contactEmail => 'e-mail';

  @override
  String get contactGithub => 'github';

  @override
  String get contactLinkedIn => 'linkedin';

  @override
  String get madeWith => 'Made with';

  @override
  String get creditsSubtitle => 'When creativity meets boredom';

  @override
  String get creditsClose => 'close';

  @override
  String contactMarkLabel(ContactDestination destination) =>
      switch (destination) {
        ContactDestination.gallery => 'Back to the gallery',
        ContactDestination.credits => 'Made with heart',
        ContactDestination.home => 'Back to the start',
        ContactDestination.cv => contactCv,
        ContactDestination.email => contactEmail,
        ContactDestination.github => contactGithub,
        ContactDestination.linkedin => contactLinkedIn,
      };

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
