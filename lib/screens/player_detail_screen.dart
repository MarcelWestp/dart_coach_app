import 'package:flutter/material.dart';
import '../models/exercise_model.dart';
import '../models/result_model.dart';
import '../models/user_model.dart';
import '../services/exercise_service.dart';
import '../services/result_service.dart';
import 'exercise_history_screen.dart';

/// Bildschirm für Trainer zur Übersicht aller Übungen eines spezifischen Spielers inkl. Trends
class PlayerDetailScreen extends StatelessWidget {
  final AppUser player;

  const PlayerDetailScreen({super.key, required this.player});

  /// Hilfsfunktion zum Extrahieren des numerischen Werts einer Übung
  double _getValue(ExerciseResult r, MetricType metricType) {
    if (metricType == MetricType.score) {
      return (r.score ?? 0).toDouble();
    } else if (metricType == MetricType.hits) {
      return (r.hits ?? 0).toDouble();
    } else if (metricType == MetricType.attempts) {
      return (r.attempts ?? 0).toDouble();
    } else if (metricType == MetricType.timeInSeconds) {
      return (r.timeInSeconds ?? 0).toDouble();
    }
    return 0.0;
  }

  /// Berechnet den 30-Tage-Trend für eine bestimmte Übung
  TrendData _calculateTrend(
    List<ExerciseResult> results,
    MetricType metricType,
  ) {
    if (results.length < 2) {
      return TrendData(
        label: 'Keine Daten',
        icon: Icons.remove,
        color: Colors.grey,
      );
    }

    // Chronologisch sortieren (alt -> neu)
    final sorted = List<ExerciseResult>.from(results)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    int mid = (sorted.length / 2).floor();
    var firstHalf = sorted.sublist(0, mid);
    var secondHalf = sorted.sublist(mid);

    double avgFirst =
        firstHalf.map((r) => _getValue(r, metricType)).reduce((a, b) => a + b) /
        firstHalf.length;
    double avgSecond =
        secondHalf
            .map((r) => _getValue(r, metricType))
            .reduce((a, b) => a + b) /
        secondHalf.length;

    if (avgFirst == 0) avgFirst = 1;

    double percentChange = ((avgSecond - avgFirst) / avgFirst) * 100;

    if (metricType == MetricType.timeInSeconds) {
      percentChange = -percentChange;
    }

    if (percentChange >= 15) {
      return TrendData(
        label: 'Stark steigend',
        icon: Icons.keyboard_double_arrow_up,
        color: Colors.green.shade700,
      );
    } else if (percentChange >= 5) {
      return TrendData(
        label: 'Steigend',
        icon: Icons.north_east,
        color: Colors.green,
      );
    } else if (percentChange <= -15) {
      return TrendData(
        label: 'Stark fallend',
        icon: Icons.keyboard_double_arrow_down,
        color: Colors.red.shade700,
      );
    } else if (percentChange <= -5) {
      return TrendData(
        label: 'Fallend',
        icon: Icons.south_east,
        color: Colors.red,
      );
    } else {
      return TrendData(
        label: 'Unverändert',
        icon: Icons.east,
        color: Colors.amber.shade800,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ExerciseService exerciseService = ExerciseService();
    final ResultService resultService = ResultService();

    return Scaffold(
      appBar: AppBar(title: Text('Übungs-Analyse: ${player.name}')),
      body: StreamBuilder<List<Exercise>>(
        stream: exerciseService.getExercises(),
        builder: (context, exerciseSnapshot) {
          if (exerciseSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final exercises = exerciseSnapshot.data ?? [];

          if (exercises.isEmpty) {
            return const Center(
              child: Text(
                'Noch keine Übungen angelegt.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];

              return StreamBuilder<List<ExerciseResult>>(
                stream: resultService.getResultsForExercise(
                  player.uid,
                  exercise.id,
                ),
                builder: (context, resultSnapshot) {
                  final allResults = resultSnapshot.data ?? [];

                  // Ergebnisse der letzten 30 Tage filtern
                  final now = DateTime.now();
                  final thirtyDaysAgo = now.subtract(const Duration(days: 30));
                  final recentResults = allResults
                      .where((r) => r.timestamp.isAfter(thirtyDaysAgo))
                      .toList();

                  final trend = _calculateTrend(
                    recentResults,
                    exercise.metricType,
                  );
                  final int playCount = recentResults.length;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: trend.color.withOpacity(0.2),
                        child: Icon(trend.icon, color: trend.color),
                      ),
                      title: Text(
                        exercise.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Letzte 30 Tage: $playCount x gespielt\n30-Tage-Trend: ${trend.label}',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // Klick auf die Übung öffnet das bekannte Detail-Diagramm
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ExerciseHistoryScreen(
                              exercise: exercise,
                              playerId: player.uid,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
