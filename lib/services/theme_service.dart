import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service zur lokalen Speicherung und Abfrage des gewählten ThemeMode
class ThemeService {
  static const String _themeKey = 'user_theme_mode';

  /// Speichert den ausgewählten ThemeMode als String
  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name); // 'system', 'light' oder 'dark'
  }

  /// Lädt den gespeicherten ThemeMode aus den Einstellungen.
  /// Falls noch nichts gespeichert wurde, wird ThemeMode.system zurückgegeben.
  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedTheme = prefs.getString(_themeKey);

    if (savedTheme == 'light') {
      return ThemeMode.light;
    } else if (savedTheme == 'dark') {
      return ThemeMode.dark;
    }
    
    return ThemeMode.system;
  }
}