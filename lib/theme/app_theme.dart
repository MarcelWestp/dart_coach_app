import 'package:flutter/material.dart';

/// Zentrale Klasse zur Definition der App-Farbschemata (Light & Dark Mode)
class AppTheme {
  // Primärfarbe für das Darts-Design (Kräftiges Orange)
  static const Color primaryColor = Colors.deepOrange;

  /// HELL-THEME (Light Mode)
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      // KORREKTUR 1: 0xFFF8F9FA statt 0xFPF8F9FA
      scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Sanftes Off-White
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
      ),
      // KORREKTUR 2: CardThemeData statt CardTheme
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  /// DUNKEL-THEME (Dark Mode)
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: primaryColor,
      surface: const Color(0xFF1E1E1E), // Dunkelgrau für Karten & Dialoge
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF121212), // Anthrazit/Schwarz
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
      ),
      // KORREKTUR 3: CardThemeData statt CardTheme
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      // KORREKTUR 4: DialogThemeData statt DialogTheme
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF1E1E1E),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1E1E1E),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}