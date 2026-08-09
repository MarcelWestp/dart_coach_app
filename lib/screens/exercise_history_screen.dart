import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/exercise_model.dart';
import '../models/result_model.dart';
import '../services/result_service.dart';

/// Typen der Filteroptionen
enum FilterType { last30Days, last90Days, specificYear, all }

/// Klasse zur flexiblen Darstellung der Filteroptionen (inkl. Jahreszahlen)
class FilterOption {
  final FilterType type;
  final int? year; // Nur gefüllt, wenn type == FilterType.specificYear
  final String label;

  FilterOption({required this.type, this.year, required this.label});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterOption &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          year == other.year;

  @override
  int get hashCode => type.hashCode ^ year.hashCode;
}

/// Ergebnis der Trend-Berechnung
class TrendData {
  final String label;
  final IconData icon;
  final Color color;

  TrendData({required this.label, required this.icon, required this.color});
}

/// Bildschirm zur Anzeige des Verlaufs, der Statistiken und des Trends einer Übung
class ExerciseHistoryScreen extends StatefulWidget {
  final Exercise exercise;
  final String playerId;

  const ExerciseHistoryScreen({
    super.key,
    required this.exercise,
    required this.playerId,
  });

  @override
  State<ExerciseHistoryScreen> createState() => _ExerciseHistoryScreenState();
}

class _ExerciseHistoryScreenState extends State<ExerciseHistoryScreen> {
  final ResultService _resultService = ResultService();

  // Standardmäßig sind die "Letzten 30 Tage" ausgewählt
  late FilterOption _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = FilterOption(
      type: FilterType.last30Days,
      label: 'Letzte 30 Tage',
    );
  }

  /// Hilfsfunktion zum Extrahieren des relevanten numerischen Werts
  double _getValue(ExerciseResult r) {
    if (widget.exercise.metricType == MetricType.score) {
      return (r.score ?? 0).toDouble();
    } else if (widget.exercise.metricType == MetricType.hits) {
      return r.hits?.toDouble() ?? 0.0;
    } else if (widget.exercise.metricType == MetricType.attempts) {
      return r.attempts?.toDouble() ?? 0.0;
    } else if (widget.exercise.metricType == MetricType.timeInSeconds) {
      return (r.timeInSeconds ?? 0).toDouble();
    }
    return 0;
  }

  /// Berechnet den 5-Stufen-Trend basierend auf den letzten 30 Tagen
  TrendData _calculateTrend(List<ExerciseResult> allResults) {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final recentResults =
        allResults.where((r) => r.timestamp.isAfter(thirtyDaysAgo)).toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (recentResults.length < 2) {
      return TrendData(
        label: 'Keine Daten',
        icon: Icons.remove,
        color: Colors.grey,
      );
    }

    int mid = (recentResults.length / 2).floor();
    var firstHalf = recentResults.sublist(0, mid);
    var secondHalf = recentResults.sublist(mid);

    double avgFirst =
        firstHalf.map(_getValue).reduce((a, b) => a + b) / firstHalf.length;
    double avgSecond =
        secondHalf.map(_getValue).reduce((a, b) => a + b) / secondHalf.length;

    if (avgFirst == 0) avgFirst = 1;

    double percentChange = ((avgSecond - avgFirst) / avgFirst) * 100;

    if (widget.exercise.metricType == MetricType.timeInSeconds) {
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

  /// Erstellt die Liste aller verfügbaren Filteroptionen inklusive vorhandener Kalenderjahre
  List<FilterOption> _buildFilterOptions(List<ExerciseResult> allResults) {
    List<FilterOption> options = [
      FilterOption(type: FilterType.last30Days, label: 'Letzte 30 Tage'),
      FilterOption(type: FilterType.last90Days, label: 'Letzte 90 Tage'),
    ];

    // Vorhandene Jahre aus den Ergebnissen auslesen
    final Set<int> years = allResults.map((r) => r.timestamp.year).toSet();
    final List<int> sortedYears = years.toList()
      ..sort((a, b) => b.compareTo(a)); // Neueste Jahre zuerst

    for (int year in sortedYears) {
      options.add(
        FilterOption(
          type: FilterType.specificYear,
          year: year,
          label: 'Jahr $year',
        ),
      );
    }

    options.add(FilterOption(type: FilterType.all, label: 'Gesamter Zeitraum'));

    return options;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fortschritt: ${widget.exercise.title}')),
      body: StreamBuilder<List<ExerciseResult>>(
        stream: _resultService.getResultsForExercise(
          widget.playerId,
          widget.exercise.id,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allResults = snapshot.data ?? [];

          if (allResults.isEmpty) {
            return const Center(
              child: Text(
                'Noch keine Ergebnisse für diese Übung eingetragen.\nAbsolviere die Übung im Wochenplan und trage Werte ein!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          // Trend-Berechnung (30 Tage)
          final trend = _calculateTrend(allResults);

          // Verfügbare Filteroptionen bauen
          final filterOptions = _buildFilterOptions(allResults);

          // Falls der aktuell gewählte Filter nicht mehr in der Liste ist, auf "Letzte 30 Tage" zurückfallen
          if (!filterOptions.contains(_selectedFilter)) {
            _selectedFilter = filterOptions.first;
          }

          // Daten basierend auf dem gewählten Filter filtern
          final now = DateTime.now();
          final filteredResults = allResults.where((r) {
            if (_selectedFilter.type == FilterType.last30Days) {
              return r.timestamp.isAfter(
                now.subtract(const Duration(days: 30)),
              );
            } else if (_selectedFilter.type == FilterType.last90Days) {
              return r.timestamp.isAfter(
                now.subtract(const Duration(days: 90)),
              );
            } else if (_selectedFilter.type == FilterType.specificYear &&
                _selectedFilter.year != null) {
              return r.timestamp.year == _selectedFilter.year;
            }
            return true; // FilterType.all
          }).toList();

          // Für das Diagramm chronologisch sortieren (alt -> neu)
          final sortedFiltered = List<ExerciseResult>.from(filteredResults)
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

          // Statistiken berechnen
          final values = sortedFiltered.map(_getValue).toList();
          final maxValue = values.isNotEmpty
              ? values.reduce((a, b) => a > b ? a : b)
              : 0.0;
          final avgValue = values.isNotEmpty
              ? values.reduce((a, b) => a + b) / values.length
              : 0.0;

          // Punkte für das Liniendiagramm
          final spots = sortedFiltered.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), _getValue(entry.value));
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- ZEITRAUM-FILTER MIT JAHRESAUSWAHL ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filterzeitraum:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    DropdownButton<FilterOption>(
                      value: _selectedFilter,
                      underline: Container(height: 2, color: Colors.deepOrange),
                      items: filterOptions.map((option) {
                        return DropdownMenuItem<FilterOption>(
                          value: option,
                          child: Text(option.label),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedFilter = val);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- KENNZAHLEN & TREND-AMPEL ---
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Bestwert',
                        maxValue.toStringAsFixed(0),
                        Colors.green,
                        Icons.emoji_events,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Schnitt',
                        avgValue.toStringAsFixed(1),
                        Colors.blue,
                        Icons.functions,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        '30-Tage-Trend',
                        trend.label,
                        trend.color,
                        trend.icon,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                const Text(
                  'Leistungsverlauf',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // --- LINIENDIAGRAMM ---
                if (spots.isEmpty)
                  const SizedBox(
                    height: 200,
                    child: Center(
                      child: Text(
                        'Keine Ergebnisse im gewählten Zeitraum vorhanden.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 240,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        right: 20,
                        top: 10,
                        bottom: 10,
                      ),
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: true),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            // X-Achsen-Beschriftung mit den konkreten Spieldaten (DD.MM.)
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval:
                                    1, // Für jeden Datenpunkt eine Beschriftung rendern
                                getTitlesWidget: (double value, TitleMeta meta) {
                                  int index = value.toInt();

                                  // Validierung, ob der Index im zulässigen Bereich liegt
                                  if (index >= 0 &&
                                      index < sortedFiltered.length) {
                                    final DateTime date =
                                        sortedFiltered[index].timestamp;
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
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: Colors.deepOrange,
                              barWidth: 4,
                              isStrokeCapRound: true,
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
                  ),
                const SizedBox(height: 24),

                const Text(
                  'Historie',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // --- HISTORIEN-LISTE MIT NOTIZEN UND DURCHLÄUFEN ---
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sortedFiltered.length,
                  itemBuilder: (context, index) {
                    // Neueste Ergebnisse zuerst in der Historienliste anzeigen
                    final res =
                        sortedFiltered[sortedFiltered.length - 1 - index];
                    final dateStr =
                        '${res.timestamp.day}.${res.timestamp.month}.${res.timestamp.year}';

                    String displayVal = '';
                    if (widget.exercise.metricType == MetricType.score) {
                      displayVal = '${res.score ?? 0} Punkte';
                    } else if (widget.exercise.metricType == MetricType.hits) {
                      displayVal = '${res.hits} Treffer';
                    } else if (widget.exercise.metricType ==
                        MetricType.attempts) {
                      displayVal = '${res.attempts} Versuche';
                    } else if (widget.exercise.metricType ==
                        MetricType.timeInSeconds) {
                      displayVal = '${res.timeInSeconds ?? 0} Sek.';
                    }

                    // Falls ein Durchlauf-Index hinterlegt ist (z. B. Durchlauf 2)
                    final String roundInfo = res.roundIndex != null
                        ? ' (Durchlauf ${res.roundIndex})'
                        : '';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      elevation: 1,
                      child: ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.history,
                          color: Colors.deepOrange,
                        ),
                        title: Text(
                          '$displayVal$roundInfo',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              res.dayOfWeek != null
                                  ? '${res.dayOfWeek}, $dateStr'
                                  : dateStr,
                            ),
                            // NEU: Spieler-Bemerkung anzeigen, falls vorhanden
                            if (res.playerNote != null &&
                                res.playerNote!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.chat_bubble_outline,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '"${res.playerNote}"',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Hilfs-Widget für die kleine Statistik- und Trend-Karten
  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
