import 'package:flutter/material.dart';
import 'screens/auth/welcome_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GUCCI',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8F5F0),
        primaryColor: const Color(0xFF1A472A),
      ),
      home: const WelcomePage(),
    );
  }
}