import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/result_model.dart';
import '../models/exercise_model.dart';

/// Ein interaktives Diagramm, das die Fortschritte einer Übung über die Zeit anzeigt.
/// Auf der X-Achse werden die konkreten Spieldaten (z. B. "12.08.") dargestellt.
class ExerciseProgressChart extends StatelessWidget {
  final List<ExerciseResult> results;
  final MetricType metricType;

  const ExerciseProgressChart({
    super.key,
    required this.results,
    required this.metricType,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'Noch keine Daten für das Diagramm vorhanden.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    // 1. SCHRITT: Ergebnisse chronologisch nach Spieldatum sortieren
    final sortedResults = List<ExerciseResult>.from(results)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // 2. SCHRITT: Datenpunkte (FlSpot) erzeugen
    final List<FlSpot> spots = [];
    for (int i = 0; i < sortedResults.length; i++) {
      final res = sortedResults[i];
      double yValue = 0.0;

      // Je nach Erfassungstyp den richtigen Wert für die Y-Achse auslesen
      if (metricType == MetricType.score) {
        yValue = (res.score ?? 0).toDouble();
      } else if (metricType == MetricType.hitsAndAttempts) {
        final hits = res.hits ?? 0;
        final attempts = res.attempts ?? 1;
        // Berechnet die Trefferquote in Prozent
        yValue = attempts > 0 ? (hits / attempts) * 100 : 0.0;
      } else if (metricType == MetricType.timeInSeconds) {
        yValue = (res.timeInSeconds ?? 0).toDouble();
      }

      // X = Index der Sortierung (0, 1, 2, ...), Y = Erzielter Wert
      spots.add(FlSpot(i.toDouble(), yValue));
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              metricType == MetricType.hitsAndAttempts
                  ? 'Verlauf der Trefferquote (%)'
                  : 'Leistungsverlauf',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200, // Feste Höhe für das Diagramm
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    // X-ACHSE: SPPIELDATEN ANZEIGEN
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1, // Für jeden Datenpunkt einen Marker anzeigen
                        getTitlesWidget: (double value, TitleMeta meta) {
                          int index = value.toInt();

                          // Sicherstellen, dass der Index im Datenbereich liegt
                          if (index >= 0 && index < sortedResults.length) {
                            final DateTime date = sortedResults[index].timestamp;
                            // Formatierung des Datums: DD.MM.
                            final String formattedDate =
                                '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.';

                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                formattedDate,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.deepOrange,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.deepOrange.withOpacity(0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}