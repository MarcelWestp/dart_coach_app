import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service zur lokalen Speicherung und Abfrage des gewählten ThemeMode
class ThemeService {
  static const String _themeKey = 'user_theme_mode';

  /// Speichert den ausgewählten ThemeMode als String
  Future<void> saveThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.name);
    } catch (e) {
      debugPrint('Fehler beim Speichern des Themes: $e');
    }
  }

  /// Lädt den gespeicherten ThemeMode aus den lokalen Einstellungen.
  /// Nutzt try-catch, damit die App bei Fehlern niemals auf einem weißen Bildschirm hängen bleibt.
  Future<ThemeMode> loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedTheme = prefs.getString(_themeKey);

      if (savedTheme == 'light') {
        return ThemeMode.light;
      } else if (savedTheme == 'dark') {
        return ThemeMode.dark;
      }
    } catch (e) {
      debugPrint('Fehler beim Laden des Themes: $e');
    }

    // Fallback: Wenn nichts gespeichert ist oder ein Fehler auftritt
    return ThemeMode.system;
  }
}