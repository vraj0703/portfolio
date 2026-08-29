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

  /// The scene's ground. The mark is drawn in this same colour and reads
  /// only because the god-ray pass gives it relief, so the two must match.
  Color get sceneBackground;

  /// "TAP TO ENTER" and the drop shadow behind it.
  Color get logoOverlayText;
  Color get logoOverlayTextShadow;

  /// Glassy fill for the lines flanking the affordance: bright at the edges,
  /// nearly clear through the middle, so they read as bevelled glass.
  List<Color> get logoLineGradient;
  List<double> get logoLineStops;

  /// Base tone the metallic title shader modulates. The sheen is generated
  /// in the shader; this is the metal it is made of.
  Color get titleBase;

  /// The downward arrow inviting the user onward.
  Color get scrollCue;

  /// The contact menu's words, at rest and under the pointer.
  Color get contactMenuText;
  Color get contactMenuTextActive;

  /// The dots between one destination and the next.
  Color get contactSeparator;

  /// Laid over the whole contact section.
  ///
  /// The contact screen is the logo screen a second time, and the second
  /// time it is not the subject — the menu is. Taking the ground back is
  /// what lets a row of small words carry the screen without having to
  /// shout over a mark the size of the window.
  ///
  /// Must be darker than the ground it covers, and that is not the obvious
  /// choice it sounds like: this was [sceneBackground] at 45% for a while,
  /// which is the scene's own colour laid over the scene's own colour. It
  /// darkened nothing. All it did was lift the shadow under the mark, so
  /// the screen came out flatter but exactly as bright.
  Color get contactDim;

  /// The dark the two renderers hand over through.
  ///
  /// The corridor and the logo screen are separate engines with no frame in
  /// which both are drawing, so one goes out through this and the other
  /// comes up out of it.
  Color get sceneVeil;

  /// The credits panel, its hairline edge, and the barrier behind it.
  Color get creditsPanel;
  Color get creditsBorder;
  Color get creditsBarrier;

  /// The credits' own type: the title, the line under it, each heading, and
  /// the things credited.
  Color get creditsTitle;
  Color get creditsSubtitle;
  Color get creditsHeading;
  Color get creditsBody;
  Color get creditsAction;

  /// The gallery's own chrome: the lettering on a control and the plate it
  /// sits on, and the ground the room shows when it cannot open.
  Color get galleryControlInk;
  Color get galleryControlPlate;

  /// The ring around a control's plate.
  Color get galleryControlEdge;
  Color get galleryFailureGround;

  /// The curtain drawn over the scene while it loads.
  Color get curtain;

  /// The hot centre of the loading mark's bloom, and how far the accent is
  /// carried toward white on its way out.
  Color get loadingBloomCore;
  Color get loadingBloomHighlight;

  /// Under the scroll arrow, so it survives the lighter passages of the
  /// backdrop it travels over.
  Color get scrollCueShadow;
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

  @override
  Color get sceneBackground => const Color(0xFFC78E53);

  @override
  Color get logoOverlayText => const Color(0xFF9A482F);

  @override
  Color get logoOverlayTextShadow => const Color(0xFFD6A65F);

  @override
  List<Color> get logoLineGradient => const <Color>[
    Color.fromRGBO(214, 166, 95, 0.2),
    Color.fromRGBO(169, 95, 59, 0.05),
    Color.fromRGBO(154, 72, 47, 0.7),
    Color.fromRGBO(169, 95, 59, 0.05),
    Color.fromRGBO(214, 166, 95, 0.2),
  ];

  @override
  List<double> get logoLineStops => const <double>[0.0, 0.4, 0.5, 0.6, 1.0];

  @override
  Color get titleBase => const Color(0xFFE3E4E5);

  @override
  Color get scrollCue => const Color(0xFFE8E4DC);

  /// The contact screen's ink is the logo overlay's, at the weights each
  /// part of it is read at. Derived rather than restated so retinting the
  /// logo screen carries the contact screen with it.
  Color get _ink => logoOverlayText;

  @override
  Color get contactMenuText => _ink.withValues(alpha: 0.72);

  @override
  Color get contactMenuTextActive => _ink;

  @override
  Color get contactSeparator => _ink.withValues(alpha: 0.35);

  @override
  Color get contactDim => sceneVeil.withValues(alpha: 0.32);

  @override
  Color get sceneVeil => const Color(0xFF000000);

  @override
  Color get creditsPanel => sceneBackground;

  @override
  Color get creditsBorder => _ink.withValues(alpha: 0.18);

  @override
  Color get creditsBarrier => sceneBackground.withValues(alpha: 0.72);

  @override
  Color get creditsTitle => _ink;

  @override
  Color get creditsSubtitle => _ink.withValues(alpha: 0.6);

  @override
  Color get creditsHeading => _ink.withValues(alpha: 0.45);

  @override
  Color get creditsBody => _ink.withValues(alpha: 0.85);

  @override
  Color get creditsAction => _ink.withValues(alpha: 0.8);

  @override
  Color get galleryControlInk => const Color(0xFFF0E4CC);

  @override
  Color get galleryControlPlate => const Color(0xCC1A1512);

  @override
  Color get galleryControlEdge => galleryControlInk.withValues(alpha: 0.45);

  @override
  Color get galleryFailureGround => const Color(0xFF1A1A1A);

  @override
  Color get curtain => const Color(0xFF000000);

  @override
  Color get loadingBloomCore => const Color(0xD9FFF4DE);

  @override
  Color get loadingBloomHighlight => const Color(0xFFFFFFFF);

  @override
  Color get scrollCueShadow => const Color(0xFF000000);
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
