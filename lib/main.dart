import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Firebase Options
import 'firebase_options.dart';

// Services
import 'services/theme_service.dart';
import 'services/user_service.dart';

// Modelle
import 'models/user_model.dart';

// Screens & Widgets
import 'screens/login_screen.dart'; // Verbindet deinen LoginScreen!
import 'widgets/player_dashboard_widget.dart';
import 'widgets/trainer_dashboard_widget.dart';

/// Globaler Notifier für den aktuellen ThemeMode
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase mit den plattformspezifischen Optionen initialisieren
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Gespeichertes Theme laden (mit Fallback abgesichert)
  try {
    final themeService = ThemeService();
    final savedThemeMode = await themeService.loadThemeMode();
    themeModeNotifier.value = savedThemeMode;
  } catch (e) {
    debugPrint('Theme konnte nicht geladen werden: $e');
  }

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
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepOrange,
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepOrange,
              brightness: Brightness.dark,
            ),
          ),
          // Einstiegspunkt in die App
          home: const MainNavigationWrapper(),
        );
      },
    );
  }
}

/// Der zentrale Auth-Wrapper zur Steuerung zwischen Login und Dashboards
class MainNavigationWrapper extends StatelessWidget {
  const MainNavigationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final UserService userService = UserService();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // 1. Ladezustand der Firebase-Authentifizierung
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.deepOrange),
            ),
          );
        }

        // 2. Nutzer ist NICHT eingeloggt -> Dein LoginScreen wird angezeigt!
        if (!authSnapshot.hasData || authSnapshot.data == null) {
          return const LoginScreen();
        }

        final firebaseUser = authSnapshot.data!;

        // 3. Nutzer IST eingeloggt -> Benutzerprofil aus Firestore abfragen
        return StreamBuilder<AppUser?>(
          stream: userService.getUserDataStream(firebaseUser.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Colors.deepOrange),
                ),
              );
            }

            final appUser = userSnapshot.data;

            // Fallback, falls der Auth-User existiert, aber noch kein Firestore-Dokument hat
            if (appUser == null) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Profil wird geladen...'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => FirebaseAuth.instance.signOut(),
                        child: const Text('Abmelden'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // 4. Rollenbasierte Weiterleitung
            if (appUser.isTrainer) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Trainer Dashboard'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.logout),
                      tooltip: 'Abmelden',
                      onPressed: () => FirebaseAuth.instance.signOut(),
                    ),
                  ],
                ),
                body: TrainerDashboardWidget(trainer: appUser),
              );
            }

            // Standard: Spieler Dashboard
            return Scaffold(
              appBar: AppBar(
                title: const Text('Dart Coach'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Abmelden',
                    onPressed: () => FirebaseAuth.instance.signOut(),
                  ),
                ],
              ),
              body: PlayerDashboardWidget(user: appUser),
            );
          },
        );
      },
    );
  }
}