import 'package:flutter/material.dart';
import 'package:projects/core/di/injection.dart';
import 'package:projects/presentation/screen/flame_scene.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vishal Raj',
      theme: ThemeData.dark(),
      home: FlameScene(onClick: () {}),
      debugShowCheckedModeBanner: false,
    );
  }
}
