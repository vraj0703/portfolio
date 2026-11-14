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

  /// The far wall of the corridor: the name, and the paragraph under it.
  ///
  /// Here rather than in the routine that bakes it onto a texture. It is the
  /// longest piece of writing in the app and the one most likely to be
  /// rewritten, and a paragraph living inside a mesh builder is a paragraph
  /// nobody edits without first reading about geometry.
  String get wallName;
  String get wallStatement;

  /// The two signs painted on the gallery's marble.
  String get galleryBack;

  /// On a frame whose work is not ready yet, under its title.
  String get frameComingSoon;

  /// The testimonial wall: its first frame's title and invitation, the quiet
  /// line on the frames still empty, and the mark on a visitor's own words.
  String get testimonialsTitle;
  String get testimonialsInvite;
  String get testimonialsReserved;
  String get testimonialPending;

  /// The control that opens the recommendation form, and the form itself.
  String get recommendAddYours;
  String get recommendFormTitle;
  String get recommendName;
  String get recommendRole;
  String get recommendRelationship;
  String get recommendWords;
  String get recommendRequired;
  String get recommendSubmit;
  String get recommendCancel;
  String get recommendDone;
  String get recommendClose;

  /// The control that opens the focused work's link, and what it is called
  /// to someone who cannot see it.
  String get galleryOpen;
  String galleryOpenLabel(String title);

  /// The link drawn on a card, naming where it goes.
  String frameLink(String host);

  /// A button drawn on a card: its word and the arrow that says it acts.
  String cardButton(String word);
  String get letsConnect;

  /// How to handle the skills board, painted on the wall behind it.
  String get keyboardInstruction;

  /// The contact menu, in the order [ContactMenu] reads.
  String get contactCv;
  String get contactEmail;
  String get contactGithub;
  String get contactLinkedIn;

  /// The title screen's controls, and the drawer one of them opens.
  String get menuOpen;
  String get menuClose;
  String get menuSoundOn;
  String get menuSoundOff;
  String get menuConnect;

  /// Reads with the heart drawn after it, in the menu and again as the
  /// credits' own title — one string, because they are the same words
  /// saying the same thing in two places.
  String get madeWith;

  /// The credits dialog, opened by the heart.
  String get creditsSubtitle;
  String get creditsClose;

  /// What each mark on the menu is, for anyone who cannot see it.
  String contactMarkLabel(ContactDestination destination);

  /// The two halves of the loading readout, e.g. "LOADING..." and "007%".
  ///
  /// Two, because they are set in different faces: the word is fixed and the
  /// figure is the part that moves, and giving the figure a face of its own
  /// is what stops it reading as part of the label.
  String get loadingLabel;
  String loadingPercent(double progress);
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
  String get wallName => 'VISHAL RAJ';

  @override
  String get wallStatement =>
      'I make software that works quietly and well. For a decade I have been '
      'building mobile apps, developer tools, and lately AI systems that can '
      'think for themselves. Good engineering is invisible — you only notice '
      'it when it is missing.';

  @override
  String get galleryBack => 'BACK';

  @override
  String get frameComingSoon => 'coming soon';

  @override
  String get testimonialsTitle => 'Testimonials';

  @override
  String get testimonialsInvite =>
      'Worked with Vishal? Leave a recommendation.';

  @override
  String get testimonialsReserved => 'Reserved for the first words';

  @override
  String get testimonialPending => 'pending';

  @override
  String get recommendAddYours => 'add yours';

  @override
  String get recommendFormTitle => 'Recommend Vishal';

  @override
  String get recommendName => 'Your name';

  @override
  String get recommendRole => 'Role and company';

  @override
  String get recommendRelationship => 'How you worked together';

  @override
  String get recommendWords => 'Your words';

  @override
  String get recommendRequired => 'Needed';

  @override
  String get recommendSubmit => 'Copy and open LinkedIn';

  @override
  String get recommendCancel => 'Cancel';

  /// Shown once the words are copied and LinkedIn is open in a new tab.
  @override
  String get recommendDone =>
      "Copied. On Vishal's LinkedIn, choose More > Recommend and paste.";

  @override
  String get recommendClose => 'Done';

  @override
  String get galleryOpen => 'open';

  @override
  String galleryOpenLabel(String title) => 'Open $title';

  @override
  String frameLink(String host) => '$host  ↗';

  @override
  String cardButton(String word) => '$word  →';

  @override
  String get letsConnect => "LET'S CONNECT";

  @override
  // Two gestures and nothing else. The visitor has arrived at the end of a
  // long walk and is looking at the board, not reading a manual — anything
  // longer than a line goes unread, and a line that has to be studied is
  // worse than no line, because it takes the attention the board wants.
  String get keyboardInstruction => 'Scroll to end, Drag, Rotate, Click a key';

  @override
  String get contactCv => 'cv';

  @override
  String get contactEmail => 'e-mail';

  @override
  String get contactGithub => 'github';

  @override
  String get contactLinkedIn => 'linkedin';

  /// Its own string rather than the credits dialog's, though both are the
  /// same word: they are two panels that happen to agree, not one phrase
  /// used twice, and either could be reworded without the other following.
  /// Never drawn: the hamburger is a glyph. This is what it is called to
  /// anyone who cannot see it.
  @override
  String get menuOpen => 'Open menu';

  @override
  String get menuClose => 'close';

  /// What pressing it does, not what the switch currently is.
  ///
  /// The same convention as the radio's PLAY/STOP: a row in a list reads as
  /// something to choose, and a row labelled with the state reads as a
  /// description until somebody presses it to find out. The mark beside it
  /// shows the same thing — both the picture and the word are the outcome,
  /// so neither contradicts the other.
  @override
  String get menuSoundOn => 'sound on';

  @override
  String get menuSoundOff => 'sound off';

  @override
  String get menuConnect => "let's connect";

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
  String get loadingLabel => 'LOADING...';

  @override
  String loadingPercent(double progress) {
    // Padded to three figures so the readout does not jump a character
    // wider as it passes ten and again as it passes a hundred — in a mono
    // face that shift is the only thing on the screen that moves sideways.
    final pct = (progress * 100).round().clamp(1, 100);
    return '${pct.toString().padLeft(3, '0')}%';
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
