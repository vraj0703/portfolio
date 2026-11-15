import 'package:flutter/material.dart';
import 'package:portfolio/data/di/dependency_manager.dart';
import 'package:portfolio/data/di/injection.dart';
import 'package:portfolio/domain/analytics/analytics.dart';
import 'package:portfolio/domain/audio/app_audio.dart';
import 'package:portfolio/presentation/analytics/site_telemetry.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/domain/style/strings.dart';
import 'package:portfolio/domain/style/text_styles.dart';
import 'package:portfolio/presentation/screen/flame_scene.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const MyApp());
  // After the first frame, so the first paint never waits on analytics.
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => locate<SiteTelemetry>().start(locate<Analytics>()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const appColors = DefaultAppColors();
    const appStrings = DefaultAppStrings();
    final appAudio = locate<AppAudio>();

    return MaterialApp(
      title: appStrings.appTitle,
      theme: ThemeData.dark().copyWith(
        extensions: [
          const AppColorsExtension(colors: appColors),
          const AppStringsExtension(strings: appStrings),
          AppAudioExtension(audio: appAudio),
          AppTypographyExtension(
            typography: DefaultAppTypography(
              loadingTextColor: appColors.loadingText,
            ),
          ),
        ],
      ),
      home: const FlameScene(),
      debugShowCheckedModeBanner: false,
    );
  }
}
