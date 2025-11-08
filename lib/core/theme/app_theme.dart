import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Gem green color
  static const Color gemGreen = Color(0xFF10B981);
  static const Color gemGreenDark = Color(0xFF059669);
  static const Color gemGreenLight = Color(0xFF34D399);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: gemGreen),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.black,
      colorScheme: ColorScheme.dark(
        brightness: Brightness.dark,
        primary: gemGreen,
        onPrimary: Colors.white,
        secondary: gemGreenLight,
        onSecondary: Colors.white,
        error: Colors.red,
        onError: Colors.white,
        surface: Colors.black,
        onSurface: Colors.white,
        surfaceContainerHighest: const Color(0xFF1A1A1A),
        surfaceContainerHigh: const Color(0xFF0F0F0F),
        surfaceContainer: const Color(0xFF0A0A0A),
        surfaceContainerLow: const Color(0xFF050505),
        surfaceContainerLowest: Colors.black,
        background: Colors.black,
        onBackground: Colors.white,
      ),
    );
  }
}

