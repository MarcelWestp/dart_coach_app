import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../screens/weekly_plan_screen.dart';
import '../screens/player_detail_screen.dart';
import '../screens/player_stats_overview_screen.dart';
import 'user_avatar_widget.dart'; // NEU: Import für das universelle Avatar-Widget

/// Dashboard für Trainer mit persönlicher Kaderverwaltung
class TrainerDashboardWidget extends StatelessWidget {
  final AppUser trainer;

  const TrainerDashboardWidget({super.key, required this.trainer});

  /// Öffnet einen Dialog zum Auswählen und Zuweisen unzugewiesener Spieler
  void _showAssignPlayerDialog(BuildContext context, UserService userService) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Spieler zu meinem Kader hinzufügen'),
          content: StreamBuilder<List<AppUser>>(
            stream: userService.getUnassignedPlayers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final freePlayers = snapshot.data ?? [];

              if (freePlayers.isEmpty) {
                return const Text(
                  'Aktuell gibt es keine unzugewiesenen Spieler.',
                  style: TextStyle(color: Colors.grey),
                );
              }

              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: freePlayers.length,
                  itemBuilder: (context, index) {
                    final player = freePlayers[index];
                    return ListTile(
                      // Auch hier verwenden wir den individuellen Avatar!
                      leading: UserAvatarWidget(user: player, radius: 20),
                      title: Text(player.name),
                      subtitle: Text(player.email),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        onPressed: () async {
                          await userService.assignPlayerToTrainer(
                            player.uid,
                            trainer.uid,
                          );
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Schließen'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final UserService userService = UserService();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info-Karte Trainer
          Card(
            color: Colors.blueGrey.shade800,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Auch der Trainer nutzt sein persönliches Avatar-Bild
                  UserAvatarWidget(user: trainer, radius: 30),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Coach ${trainer.name}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Mein Trainings-Kader',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Überschrift mit Zuweisungs-Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Meine Spieler',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAssignPlayerDialog(context, userService),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Spieler zuweisen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Liste der dem Trainer zugewiesenen Spieler
          StreamBuilder<List<AppUser>>(
            stream: userService.getPlayersForTrainer(trainer.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final myPlayers = snapshot.data ?? [];

              if (myPlayers.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Du hast noch keine Spieler in deinem Kader.\nKlicke oben auf "Spieler zuweisen", um Spieler hinzuzufügen.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: myPlayers.length,
                itemBuilder: (context, index) {
                  final player = myPlayers[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      // HIER WIRD DER INDIVIDUELLE AVATAR ANGEZEIGT:
                      leading: UserAvatarWidget(user: player, radius: 22),
                      title: Text(
                        player.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(player.email),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Trends & Statistik
                          IconButton(
                            icon: const Icon(
                              Icons.show_chart,
                              color: Colors.blue,
                            ),
                            tooltip: 'Übungs-Trends & Statistik',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PlayerDetailScreen(player: player),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.bar_chart,
                              color: Colors.purple,
                            ),
                            tooltip: 'Gesamte Statistik anzeigen',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PlayerStatsOverviewScreen(
                                    playerId: player.uid,
                                    playerName: player.name,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Wochenplan
                          ElevatedButton.icon(
                            icon: const Icon(Icons.calendar_month, size: 16),
                            label: const Text('Wochenplan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => WeeklyPlanScreen(
                                    targetPlayerId: player.uid,
                                    isTrainer: true,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Entfernen
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red,
                            ),
                            tooltip: 'Aus Kader entfernen',
                            onPressed: () async {
                              await userService.removePlayerFromTrainer(
                                player.uid,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
