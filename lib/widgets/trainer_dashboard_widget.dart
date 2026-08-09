import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../screens/weekly_plan_screen.dart';
import '../screens/player_stats_overview_screen.dart';
import 'user_avatar_widget.dart';

/// Dashboard für Trainer mit persönlicher Kaderverwaltung (für Mobilgeräte optimiert)
class TrainerDashboardWidget extends StatelessWidget {
  final AppUser trainer;

  const TrainerDashboardWidget({super.key, required this.trainer});

  /// Öffnet einen Dialog zum Auswählen und Zuweisen unzugewiesener Spieler
  void _showAssignPlayerDialog(BuildContext context, UserService userService) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Spieler zum Kader hinzufügen'),
          content: StreamBuilder<List<AppUser>>(
            stream: userService.getUnassignedPlayers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.deepOrange),
                );
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
                      contentPadding: EdgeInsets.zero,
                      leading: UserAvatarWidget(user: player, radius: 20),
                      title: Text(
                        player.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        player.email,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        tooltip: 'Spieler hinzufügen',
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

  /// Bestätigungsdialog zum Entfernen eines Spielers aus dem Kader
  void _confirmRemovePlayer(
    BuildContext context,
    UserService userService,
    AppUser player,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Spieler entfernen?'),
        content: Text(
          'Möchtest du ${player.name} wirklich aus deinem Kader entfernen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              await userService.removePlayerFromTrainer(player.uid);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Entfernen'),
          ),
        ],
      ),
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
          // 1. INFO-KARTE TRAINER (Header)
          Card(
            color: Colors.blueGrey.shade800,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  UserAvatarWidget(user: trainer, radius: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Coach ${trainer.name}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Mein Trainings-Kader',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. ÜBERSCHRIFT MIT MITGLIED-ZUWENIG-BUTTON
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Meine Spieler',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAssignPlayerDialog(context, userService),
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text('Zuweisen', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. LISTE DER DEM TRAINER ZUGEWIESENEN SPIELER
          StreamBuilder<List<AppUser>>(
            stream: userService.getPlayersForTrainer(trainer.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.deepOrange),
                );
              }

              final myPlayers = snapshot.data ?? [];

              if (myPlayers.isEmpty) {
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(
                      child: Text(
                        'Du hast noch keine Spieler in deinem Kader.\nKlicke oben auf "Zuweisen", um Spieler hinzuzufügen.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
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
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          // KOPFZEILE DES SPIELERS (Avatar, Name, Email)
                          Row(
                            children: [
                              UserAvatarWidget(user: player, radius: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      player.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      player.email,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              // Entf.-Button oben rechts
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                tooltip: 'Aus Kader entfernen',
                                onPressed: () => _confirmRemovePlayer(
                                  context,
                                  userService,
                                  player,
                                ),
                              ),
                            ],
                          ),

                          const Divider(height: 16),

                          // BILDGESCHNITTENE BUTTON-ZEILE FÜR MOBIL
                          Row(
                            children: [
                              // Button: Statistik
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(
                                    Icons.bar_chart,
                                    size: 16,
                                    color: Colors.purple,
                                  ),
                                  label: const Text(
                                    'Statistik',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.purple,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.purple),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            PlayerStatsOverviewScreen(
                                          playerId: player.uid,
                                          playerName: player.name,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Button: Wochenplan
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(
                                    Icons.calendar_month,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Wochenplan',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepOrange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    visualDensity: VisualDensity.compact,
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
                              ),
                            ],
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