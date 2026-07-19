import 'package:flutter/material.dart';
import 'package:flutter_project/login_screen.dart';
import 'package:flutter_project/theme_controller.dart';

void main() {
  runApp(const SpeakFlowApp());
}

class SpeakFlowApp extends StatelessWidget {
  const SpeakFlowApp({super.key});

  ThemeData _buildLightTheme() {
    const primary = Color(0xFFF97316);
    const background = Color(0xFFFFF9F1);
    const surface = Colors.white;
    const text = Color(0xFF29231D);
    const subtitle = Color(0xFF74685A);
    const border = Color(0xFFF1E5D6);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      surface: surface,
    );

    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      splashFactory: InkRipple.splashFactory,

      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(
          color: text,
        ),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: text,
          fontWeight: FontWeight.w900,
        ),
        headlineMedium: TextStyle(
          color: text,
          fontWeight: FontWeight.w900,
        ),
        headlineSmall: TextStyle(
          color: text,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: TextStyle(
          color: text,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: TextStyle(
          color: text,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(
          color: text,
        ),
        bodyMedium: TextStyle(
          color: subtitle,
        ),
      ),

      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: border,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFFCF8),
        labelStyle: const TextStyle(
          color: subtitle,
        ),
        hintStyle: TextStyle(
          color: subtitle.withValues(alpha: 0.65),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Colors.redAccent,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 2,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              primary.withValues(alpha: 0.42),
          disabledForegroundColor:
              Colors.white.withValues(alpha: 0.70),
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 13,
          ),
          side: BorderSide(
            color: primary.withValues(alpha: 0.32),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      floatingActionButtonTheme:
          const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        titleTextStyle: const TextStyle(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: const TextStyle(
          color: subtitle,
          fontSize: 14,
          height: 1.5,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: text,
        contentTextStyle: const TextStyle(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),

      progressIndicatorTheme:
          const ProgressIndicatorThemeData(
        color: primary,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const primary = Color(0xFF38BDF8);
    const background = Color(0xFF0B1220);
    const surface = Color(0xFF152238);
    const inputSurface = Color(0xFF0F1A2C);
    const text = Colors.white;
    const subtitle = Colors.white60;
    const border = Color(0xFF2C405D);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      surface: surface,
    );

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      splashFactory: InkRipple.splashFactory,

      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(
          color: text,
        ),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: text,
          fontWeight: FontWeight.w900,
        ),
        headlineMedium: TextStyle(
          color: text,
          fontWeight: FontWeight.w900,
        ),
        headlineSmall: TextStyle(
          color: text,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: TextStyle(
          color: text,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: TextStyle(
          color: text,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(
          color: text,
        ),
        bodyMedium: TextStyle(
          color: subtitle,
        ),
      ),

      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: border,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputSurface,
        labelStyle: const TextStyle(
          color: subtitle,
        ),
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.30),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Colors.redAccent,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 2,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: background,
          disabledBackgroundColor:
              primary.withValues(alpha: 0.35),
          disabledForegroundColor:
              background.withValues(alpha: 0.65),
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 13,
          ),
          side: BorderSide(
            color: primary.withValues(alpha: 0.34),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      floatingActionButtonTheme:
          const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: background,
        elevation: 4,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        titleTextStyle: const TextStyle(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          height: 1.5,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surface,
        contentTextStyle: const TextStyle(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),

      progressIndicatorTheme:
          const ProgressIndicatorThemeData(
        color: primary,
      ),
    );
  }

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
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          home: const LoginScreen(),
        );
      },
    );
  }
}
