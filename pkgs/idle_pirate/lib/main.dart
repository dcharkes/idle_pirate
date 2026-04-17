import 'package:flutter/material.dart';
import 'state/game_controller.dart';
import 'ui/screens/game_screen.dart';

void main() {
  final controller = GameController();
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
