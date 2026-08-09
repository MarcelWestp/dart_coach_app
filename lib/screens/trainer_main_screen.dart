import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../widgets/trainer_dashboard_widget.dart';
import 'member_management_screen.dart';
import 'exercise_list_screen.dart'; // NEU: Dein exakter Dateiname
import 'performance_test_screen.dart';
import 'profile_screen.dart';

/// Haupt-Screen für Trainer inklusive Bottom-NavigationBar zur Navigation zwischen allen Bereichen
class TrainerMainScreen extends StatefulWidget {
  final AppUser trainer;

  const TrainerMainScreen({super.key, required this.trainer});

  @override
  State<TrainerMainScreen> createState() => _TrainerMainScreenState();
}

class _TrainerMainScreenState extends State<TrainerMainScreen> {
  // Index der aktuell ausgewählten Seite (0 = Kader)
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Liste aller verfügbaren Trainer-Ansichten
    final List<Widget> pages = [
      // Tab 0: Kader & Wochenpläne
      TrainerDashboardWidget(trainer: widget.trainer),
      
      // Tab 1: Mitglieder verwalten (mit Trainer-ID)
      MemberManagementScreen(currentTrainerId: widget.trainer.uid),
      
      // Tab 2: Übungen verwalten (Verlinkung auf deinen ExerciseListScreen)
      const ExerciseListScreen(),
      
      // Tab 3: Leistungstests verwalten
      const PerformanceTestScreen(),
      
      // Tab 4: Profil & Einstellungen
      ProfileScreen(user: widget.trainer),
    ];

    // Titelzeile in der AppBar passend zum gewählten Tab
    final List<String> titles = [
      'Trainer Dashboard',
      'Mitglieder verwalten',
      'Übungen verwalten',
      'Leistungstests',
      'Mein Profil',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Abmelden',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      // Zeigt den aktuell gewählten Bildschirm an
      body: pages[_currentIndex],

      // Untere Navigationsleiste
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Colors.deepOrange),
            label: 'Kader',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: Colors.deepOrange),
            label: 'Mitglieder',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center, color: Colors.deepOrange),
            label: 'Übungen',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment, color: Colors.deepOrange),
            label: 'Tests',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Colors.deepOrange),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}