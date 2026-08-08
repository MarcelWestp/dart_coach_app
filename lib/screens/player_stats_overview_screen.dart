import 'package:flutter/material.dart';
import '../models/exercise_model.dart';
import '../services/exercise_service.dart';
import 'exercise_history_screen.dart';
import 'performance_test_detail_stats_screen.dart';

/// Zentrale Statistik-Übersichtsseite für einen einzelnen Spieler.
/// Kann sowohl vom Trainer als auch vom Spieler selbst aufgerufen werden.
class PlayerStatsOverviewScreen extends StatelessWidget {
  final String playerId;
  final String playerName;

  const PlayerStatsOverviewScreen({
    super.key,
    required this.playerId,
    required this.playerName,
  });

  @override
  Widget build(BuildContext context) {
    final ExerciseService exerciseService = ExerciseService();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Statistiken: $playerName'),
          bottom: const TabBar(
            indicatorColor: Colors.deepOrange,
            labelColor: Colors.deepOrange,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(
                text: 'Übungs-Historie',
                icon: Icon(Icons.show_chart),
              ),
              Tab(
                text: 'Leistungstests',
                icon: Icon(Icons.assignment_turned_in),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: ÜBUNGS-HISTORIE & TRENDS (Bestehendes Modul)
            StreamBuilder<List<Exercise>>(
              stream: exerciseService.getExercises(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final exercises = snapshot.data ?? [];

                if (exercises.isEmpty) {
                  return const Center(
                    child: Text('Noch keine Übungen im System vorhanden.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.deepOrange,
                          child: Icon(Icons.fitness_center, color: Colors.white),
                        ),
                        title: Text(
                          exercise.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(exercise.description),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // Öffnet den bestehenden Historien-Bildschirm der jeweiligen Übung
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ExerciseHistoryScreen(
                                exercise: exercise,
                                playerId: playerId,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),

            // TAB 2: LEISTUNGSTEST-DETAILSTATISTIKEN
            PerformanceTestDetailStatsScreen(
              playerId: playerId,
              playerName: playerName,
            ),
          ],
        ),
      ),
    );
  }
}