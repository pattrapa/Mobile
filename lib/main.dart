import 'package:flutter/material.dart';
import 'package:flutter_project/login_screen.dart';
import 'package:flutter_project/theme_controller.dart';

void main() {
  runApp(const SpeakFlowApp());
}

class SpeakFlowApp extends StatelessWidget {
  const SpeakFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.isDarkMode,
      builder: (context, isDarkMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SpeakFlow',
          themeMode:
              isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor:
                const Color(0xFFFAF6EE),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFD97706),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor:
                const Color(0xFF0F172A),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF38BDF8),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: const LoginScreen(),
        );
      },
    );
  }
}