import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'state/game_controller.dart';
import 'state/translations.dart';
import 'ui/screens/game_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final box = await Hive.openBox('game_state');
  
  await loadTranslations('en');

  final controller = GameController(box: box);
  runApp(MyApp(controller: controller));
}

class MyApp extends StatelessWidget {
  final GameController controller;

  const MyApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Idle Pirate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: GameScreen(controller: controller),
    );
  }
}
