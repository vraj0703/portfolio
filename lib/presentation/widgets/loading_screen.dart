import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:portfolio/domain/config/logo_config.dart';
import 'package:portfolio/domain/models/loading_progress.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/domain/style/strings.dart';
import 'package:portfolio/domain/style/text_styles.dart';

/* -- Shared geometry and timing ---------------------------------------- */

/// Fraction of viewport width the mark occupies, capped so it stays sane on
/// an ultrawide monitor.

/// The logo art is 175x150; keeping the ratio avoids distorting it.
const double _aspect = LogoConfig.markAspect;

/// Where in the exit the flash peaks. Early, so the burst reads as the cause
/// of the dissolve rather than an afterthought.
const double _flashPeak = 0.18;
const double _flashEnd = 0.72;
const double _flashStrength = 0.42;

/// The exit is over by this point — the mark and aura have fully cleared,
/// leaving the flash to finish alone.
const double _dissolveEnd = 0.75;

/// Gap between the mark and the readout, and the readout's approximate line
/// height. The height only anchors the burst on the mark, so an estimate is
/// enough — no layout depends on it.
const double _readoutGap = 20;
const double _readoutHeight = 18;

/// How far the mark and aura have cleared, `0`..`1`.
///
/// Compressed into [_dissolveEnd] so they are gone while the flash is still
/// burning off, rather than lingering as a blurred smear underneath it.
double _fade(double exit) =>
    Curves.easeInQuad.transform((exit / _dissolveEnd).clamp(0.0, 1.0));

/* -- Loading screen ----------------------------------------------------- */

/// The loading curtain: mark, aura, and a percentage readout.
///
/// Stateless. The two things that would normally justify a [StatefulWidget] —
/// smoothing the bar between milestone reports, and running the exit — are
/// instead an implicit [TweenAnimationBuilder] and a plain [exit] input
/// driven by the scene's reveal. Nothing here owns a controller.
///
/// Everything it draws is a function of its inputs: [progress] from
/// `SceneState.loading`, and [exit] from the curtain's opening.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key, required this.progress, this.exit = 0});

  final LoadingProgress progress;

  /// How far through the exit animation this is, `0` = fully present,
  /// `1` = fully gone.
  ///
  /// Driven by the curtain's reveal so the mark leaves *with* the reveal
  /// rather than popping out a frame before it starts. The mark swells and
  /// blurs, the aura expands, and a flash blooms from behind it as it goes —
  /// the load ends on a burst rather than a dimmer switch.
  final double exit;

  /// How long the bar takes to catch up to a new report. Long enough to read
  /// as motion, short enough not to lag a fast load.
  static const Duration smoothing = Duration(milliseconds: 300);

  /// Opacity of the burst: a quick onset to [_flashPeak], then a slower
  /// decay. Both sides approach the peak with near-zero slope, so it blooms
  /// rather than strobes. Exposed so tests can pin the shape.
  static double flashOpacity(double exit) {
    final e = exit.clamp(0.0, 1.0);
    if (e <= 0) return 0;
    if (e < _flashPeak) {
      return Curves.easeOutCubic.transform(e / _flashPeak) * _flashStrength;
    }
    final t = ((e - _flashPeak) / (_flashEnd - _flashPeak)).clamp(0.0, 1.0);
    return (1 - Curves.easeInOutCubic.transform(t)) * _flashStrength;
  }

  @override
  Widget build(BuildContext context) {
    final e = exit.clamp(0.0, 1.0);

    // The backdrop clears a little ahead of the mark, so the curtain opening
    // behind it shows through while the mark is still dissolving over it.
    final dissolve = Curves.easeIn.transform(e);
    final flash = flashOpacity(e);

    final size = MediaQuery.sizeOf(context);
    final logoWidth = LogoConfig.loadingMarkWidthFor(
      viewportWidth: size.width,
      viewportHeight: size.height,
    );
    final logoHeight = logoWidth * _aspect;

    // Anchor the burst on the mark rather than the viewport. The column also
    // holds the readout, so the mark sits above centre; without this the
    // light appears to originate just below the logo.
    final blockHeight = logoHeight + _readoutGap + _readoutHeight;
    final markOffset = logoHeight / 2 - blockHeight / 2;
    final flashCenter = Alignment(0, markOffset / (size.height / 2));

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ColoredBox(
          color: context.colors.loadingBackdrop.withValues(alpha: 1 - dissolve),
        ),

        TweenAnimationBuilder<double>(
          tween: Tween<double>(end: progress.value.clamp(0.0, 1.0)),
          duration: smoothing,
          curve: Curves.easeOut,
          builder: (context, p, _) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    width: logoWidth,
                    height: logoHeight,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        _LoadingAura(size: logoWidth, progress: p, exit: e),
                        _LoadingMark(
                          width: logoWidth,
                          height: logoHeight,
                          progress: p,
                          exit: e,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: _readoutGap),
                  _LoadingReadout(width: logoWidth, progress: p, exit: e),
                ],
              ),
            );
          },
        ),

        if (flash > 0.001) _FlashBurst(opacity: flash, center: flashCenter),
      ],
    );
  }
}

/* -- Parts -------------------------------------------------------------- */

/// The burst that fires as the mark leaves.
///
/// White-hot at the centre, falling through the accent to fully transparent
/// at the edges, so it reads as light thrown outward *from* the mark. An
/// earlier version had the outer stop opaque white, which lit the whole frame
/// evenly and looked like fog rather than a flash.
class _FlashBurst extends StatelessWidget {
  const _FlashBurst({required this.opacity, required this.center});

  final double opacity;
  final Alignment center;

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.loadingAccent;

    return IgnorePointer(
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: center,
              radius: 0.85,
              colors: <Color>[
                context.colors.loadingBloomCore,
                Color.lerp(
                  accent,
                  context.colors.loadingBloomHighlight,
                  0.55,
                )!.withValues(alpha: 0.62),
                accent.withValues(alpha: 0.28),
                accent.withValues(alpha: 0),
              ],
              stops: const <double>[0.0, 0.18, 0.46, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

/// Warm halo behind the mark.
///
/// Brightness ramps quadratically with load, so it stays almost invisible
/// early and blooms as loading finishes; on exit it expands outward and
/// clears.
///
/// The falloff comes from the gradient's stops rather than a blur filter. An
/// [ImageFiltered] blur is clipped to its own layer bounds, which left a
/// visible rectangular seam around the halo.
class _LoadingAura extends StatelessWidget {
  const _LoadingAura({
    required this.size,
    required this.progress,
    required this.exit,
  });

  final double size;
  final double progress;
  final double exit;

  @override
  Widget build(BuildContext context) {
    final opacity = (progress * progress * 0.7) * (1 - _fade(exit));
    if (opacity <= 0.001) return const SizedBox.shrink();

    final accent = context.colors.loadingAccent;

    return Transform.translate(
      offset: Offset(0, -size * 0.05),
      child: Transform.scale(
        // Expands hard on the way out, so the halo reads as the flash
        // spreading rather than simply dimming.
        scale: (1 + progress * 0.6) + exit * 3,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: SizedBox(
            width: size * 2.2,
            height: size * 2.2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    accent.withValues(alpha: 0.62),
                    accent.withValues(alpha: 0.30),
                    accent.withValues(alpha: 0.08),
                    accent.withValues(alpha: 0),
                  ],
                  stops: const <double>[0.0, 0.22, 0.42, 0.62],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The mark itself.
///
/// The source art is a black glyph on transparency, so it is inverted to read
/// against the near-black backdrop. Inverting only the colour channels
/// preserves alpha, giving a white glyph rather than a white box.
///
/// On exit it swells and blurs as it fades, dissolving into the flash instead
/// of shrinking away from the viewer.
class _LoadingMark extends StatelessWidget {
  const _LoadingMark({
    required this.width,
    required this.height,
    required this.progress,
    required this.exit,
  });

  final double width;
  final double height;
  final double progress;
  final double exit;

  static const ColorFilter _invert = ColorFilter.matrix(<double>[
    -1, 0, 0, 0, 255, //
    0, -1, 0, 0, 255, //
    0, 0, -1, 0, 255, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    final markOpacity = 1 - _fade(exit);
    if (markOpacity <= 0.001) return const SizedBox.shrink();

    final logo = ColorFiltered(
      colorFilter: _invert,
      child: Image.asset(
        'assets/images/logo.png',
        width: width,
        height: height,
        fit: BoxFit.contain,
      ),
    );

    // Bloom that strengthens as loading completes, and again as the mark
    // leaves. A BoxShadow would trace the widget's rectangle rather than the
    // glyph, so this is a blurred tinted copy sitting behind the crisp one.
    final bloom = math.max(progress, exit);
    Widget content = bloom <= 0.01
        ? logo
        : Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Opacity(
                opacity: (bloom * 0.8).clamp(0.0, 1.0),
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(
                    sigmaX: bloom * 15,
                    sigmaY: bloom * 15,
                  ),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      context.colors.loadingAccent,
                      BlendMode.srcATop,
                    ),
                    child: logo,
                  ),
                ),
              ),
              logo,
            ],
          );

    final blur = exit * 8;
    if (blur > 0.01) {
      content = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      );
    }

    return Transform.scale(
      scale: 1 + exit * 0.45,
      child: Opacity(opacity: markOpacity.clamp(0.0, 1.0), child: content),
    );
  }
}

/// Right-aligned percentage readout under the mark.
///
/// It lifts away and clears early in the exit, so it is gone before the flash
/// peaks. It stays in the tree throughout rather than being swapped out for a
/// placeholder: the column is centred, so a child that stops occupying space
/// shortens it and snaps the mark downward mid-exit.
class _LoadingReadout extends StatelessWidget {
  const _LoadingReadout({
    required this.width,
    required this.progress,
    required this.exit,
  });

  final double width;
  final double progress;
  final double exit;

  @override
  Widget build(BuildContext context) {
    final lift = Curves.easeIn.transform((exit / 0.4).clamp(0.0, 1.0));

    return Transform.translate(
      offset: Offset(0, -8 * lift),
      child: Opacity(
        opacity: (1 - lift).clamp(0.0, 1.0),
        child: SizedBox(
          width: width,
          child: Text(
            context.strings.loadingProgress(progress),
            textAlign: TextAlign.right,
            // Face, size and spacing come from the theme; only the alpha is
            // animated, brightening as the load completes.
            style: context.typography.loading.copyWith(
              color: context.colors.loadingText.withValues(
                alpha: 0.35 + progress * 0.35,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
