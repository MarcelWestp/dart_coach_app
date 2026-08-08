import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'models/user_model.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/exercise_list_screen.dart';
import 'screens/performance_test_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/member_management_screen.dart';
import 'widgets/player_dashboard_widget.dart';
import 'widgets/trainer_dashboard_widget.dart';

/// Globaler Notifier für den ThemeMode (System, Light, Dark)
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier<ThemeMode>(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder hört auf Änderungen am ThemeMode
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'Dart Coach App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,      // Helles Design
          darkTheme: AppTheme.darkTheme,    // Dunkles Design
          themeMode: currentMode,          // Aktueller Modus (System / Light / Dark)
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return HomeScreen(uid: snapshot.data!.uid);
        }

        return const LoginScreen();
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  final String uid;

  const HomeScreen({
    super.key,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return FutureBuilder<AppUser?>(
      future: authService.getUserProfile(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Benutzerprofil nicht gefunden.')),
          );
        }

        // SPERRBILDSCHIRM: Falls Konto noch nicht freigeschaltet
        if (!user.approved) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Wartet auf Freischaltung'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => authService.logout(),
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hourglass_top,
                      size: 80, color: Colors.deepOrange),
                  const SizedBox(height: 24),
                  Text(
                    'Hallo ${user.name}!',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Dein Konto wurde erfolgreich erstellt, erfordert jedoch die Freischaltung durch einen Trainer/Admin.\n\nBitte gedulde dich kurz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => authService.logout(),
                    icon: const Icon(Icons.logout),
                    label: const Text('Abmelden'),
                  ),
                ],
              ),
            ),
          );
        }

        // FREIGESCHALTETES DASHBOARD
        return Scaffold(
          appBar: AppBar(
            title: Text(user.isTrainer ? 'Trainer Dashboard' : 'Spieler Dashboard'),
            actions: [
              IconButton(
                icon: const Icon(Icons.account_circle),
                tooltip: 'Mein Profil & Einstellungen',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(user: user),
                    ),
                  );
                },
              ),
              if (user.isTrainer) ...[
                IconButton(
                  icon: const Icon(Icons.admin_panel_settings),
                  tooltip: 'Mitgliederverwaltung',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            MemberManagementScreen(currentTrainerId: user.uid),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.list_alt),
                  tooltip: 'Übungen verwalten',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const ExerciseListScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.assignment),
                  tooltip: 'Leistungstests',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const PerformanceTestScreen()),
                    );
                  },
                ),
              ],
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => authService.logout(),
              ),
            ],
          ),
          body: user.isTrainer
              ? TrainerDashboardWidget(trainer: user)
              : PlayerDashboardWidget(user: user),
        );
      },
    );
  }
}