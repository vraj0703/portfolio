import 'package:flutter/material.dart';
import 'package:portfolio/core/di/injection.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/domain/style/strings.dart';
import 'package:portfolio/domain/style/text_styles.dart';
import 'package:portfolio/presentation/screen/flame_scene.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const appColors = DefaultAppColors();
    const appStrings = DefaultAppStrings();

    return MaterialApp(
      title: appStrings.appTitle,
      theme: ThemeData.dark().copyWith(
        extensions: [
          const AppColorsExtension(colors: appColors),
          const AppStringsExtension(strings: appStrings),
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
