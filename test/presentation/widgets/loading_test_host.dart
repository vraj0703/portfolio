import 'package:flutter/material.dart';
import 'package:portfolio/domain/models/loading_phase.dart';
import 'package:portfolio/domain/models/loading_progress.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/domain/style/text_styles.dart';

/// A [LoadingProgress] with every phase at [fraction].
LoadingProgress progressAt(double fraction) {
  var progress = LoadingProgress.empty;
  for (final phase in LoadingPhase.values) {
    progress = progress.advance(phase, fraction);
  }
  return progress;
}

/// Wraps [child] in the same theme extensions `main.dart` installs.
///
/// The colour and typography accessors fall back to defaults when no
/// extension is present, so tests would pass without this — but they would be
/// exercising the fallback rather than the app's actual palette and type.
/// Goldens especially need the real thing to mean anything.
Widget loadingHost(Widget child, {Size size = const Size(1280, 720)}) {
  const appColors = DefaultAppColors();

  return MediaQuery(
    data: MediaQueryData(size: size),
    child: Theme(
      data: ThemeData.dark().copyWith(
        extensions: <ThemeExtension<dynamic>>[
          const AppColorsExtension(colors: appColors),
          AppTypographyExtension(
            typography: const DefaultAppTypography(
              loadingTextColor: Color(0xFFFFFFFF),
            ),
          ),
        ],
      ),
      child: Directionality(textDirection: TextDirection.ltr, child: child),
    ),
  );
}
