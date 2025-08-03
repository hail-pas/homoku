import 'package:flutter/material.dart';
import 'six_moku_game.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '六子棋游戏',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      home: const SixMokuGame(),
      debugShowCheckedModeBanner: false,
    );
  }
}
