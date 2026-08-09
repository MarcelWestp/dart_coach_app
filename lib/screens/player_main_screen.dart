import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../widgets/player_dashboard_widget.dart';
import 'profile_screen.dart';
import 'user_search_screen.dart'; // NEU: Import des Such-Screens

/// Haupt-Screen für Spieler inklusive Navigation zwischen Dashboard, Suche und Profil
class PlayerMainScreen extends StatefulWidget {
  final AppUser user;

  const PlayerMainScreen({super.key, required this.user});

  @override
  State<PlayerMainScreen> createState() => _PlayerMainScreenState();
}

class _PlayerMainScreenState extends State<PlayerMainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Liste der Seiten (jetzt mit Suche an zweiter Stelle)
    final List<Widget> pages = [
      PlayerDashboardWidget(user: widget.user),
      UserSearchScreen(currentUser: widget.user), // NEU: Such-Screen
      ProfileScreen(user: widget.user),
    ];

    // Titel für die AppBar je nach aktivem Tab
    final List<String> titles = [
      'Dart Coach',
      'Nutzer suchen', // NEU
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
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Colors.deepOrange),
            label: 'Dashboard',
          ),
          // NEU: Navigations-Ziel für die Suche
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search, color: Colors.deepOrange),
            label: 'Suche',
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