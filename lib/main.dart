import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/theme_service.dart';
// ggf. weitere Imports deines Projekts...

/// Globaler Notifier für den aktuellen ThemeMode
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Gespeichertes Theme beim App-Start laden
  final themeService = ThemeService();
  final savedThemeMode = await themeService.loadThemeMode();
  themeModeNotifier.value = savedThemeMode;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'Dart Coach App',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          // Helles Theme
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepOrange,
              brightness: Brightness.light,
            ),
          ),
          // Dunkles Theme (Darkmode)
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepOrange,
              brightness: Brightness.dark,
            ),
          ),
          home: const MainNavigationWrapper(), // Dein Haupt-Screen/Auth-Wrapper
        );
      },
    );
  }
}

/// Platzhalter-Klasse für deinen Navigations- / Auth-Wrapper
class MainNavigationWrapper extends StatelessWidget {
  const MainNavigationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Hier lädt gewöhnlich dein Auth-Stream oder Dashboard
    return const Scaffold(
      body: Center(child: Text('App geladen')),
    );
  }
}