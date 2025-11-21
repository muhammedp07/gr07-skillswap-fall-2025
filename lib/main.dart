import 'package:flutter/material.dart';
import 'screens/auth/welcome_screen.dart';

void main() {
  runApp(const SkillSwapApp());
}

class SkillSwapApp extends StatelessWidget {
  const SkillSwapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "SkillSwap",
      theme: ThemeData.dark(useMaterial3: true),
      home: const WelcomeScreen(),
    );
  }
}
