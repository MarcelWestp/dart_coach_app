import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../widgets/player_dashboard_widget.dart';
import 'profile_screen.dart';
import 'user_search_screen.dart';
import 'x01_scorer_screen.dart'; // NEU: Import unseres X01-Scorers

/// Haupt-Screen für Spieler inklusive Navigation zwischen Dashboard, X01 Scorer, Suche und Profil.
class PlayerMainScreen extends StatefulWidget {
  final AppUser user;

  const PlayerMainScreen({super.key, required this.user});

  @override
  State<PlayerMainScreen> createState() => _PlayerMainScreenState();
}

class _PlayerMainScreenState extends State<PlayerMainScreen> {
  // Speichert den Index des aktuell ausgewählten Navigations-Tabs
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // 1. Liste aller Hauptseiten für den Spieler (inklusive X01 Scorer)
    final List<Widget> pages = [
      PlayerDashboardWidget(user: widget.user),
      
      // NEU: X01 Scorer Screen mit Daten aus dem aktuellen AppUser
      X01ScorerScreen(
        playerId: widget.user.uid,
        playerName: widget.user.name, // Falls das Feld in AppUser anders heißt (z.B. displayName), hier anpassen
      ),
      
      UserSearchScreen(currentUser: widget.user),
      ProfileScreen(user: widget.user),
    ];

    // 2. Passende Titel für die AppBar je nach aktivem Tab
    final List<String> titles = [
      'Dart Coach',
      'X01 Scorer',      // NEU
      'Nutzer suchen',
      'Mein Profil',
    ];

    return Scaffold(
      // KOPFZEILE (AppBar)
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Abmelden',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),

      // HAUPTINHALT (State bleibt beim Wechsel erhalten)
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),

      // UNTERE NAVIGATIONSLEISTE (Material 3 NavigationBar mit 4 Tabs)
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          // Tab 1: Dashboard
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Colors.deepOrange),
            label: 'Dashboard',
          ),
          
          // Tab 2: NEU - X01 Scorer
          NavigationDestination(
            icon: Icon(Icons.gps_fixed_outlined),
            selectedIcon: Icon(Icons.gps_fixed, color: Colors.deepOrange),
            label: 'X01 Scorer',
          ),
          
          // Tab 3: Nutzersuche
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search, color: Colors.deepOrange),
            label: 'Suche',
          ),
          
          // Tab 4: Profil
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