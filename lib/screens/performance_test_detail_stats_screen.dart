import 'package:flutter/material.dart';
import '../models/performance_test_model.dart';
import '../models/exercise_model.dart';
import '../services/test_service.dart';
import '../services/exercise_service.dart';

/// Spezialisierter Statistik-Bildschirm für Leistungstests mit dynamischen Spalten
class PerformanceTestDetailStatsScreen extends StatefulWidget {
  final String playerId;
  final String playerName;

  const PerformanceTestDetailStatsScreen({
    super.key,
    required this.playerId,
    required this.playerName,
  });

  @override
  State<PerformanceTestDetailStatsScreen> createState() =>
      _PerformanceTestDetailStatsScreenState();
}

class _PerformanceTestDetailStatsScreenState
    extends State<PerformanceTestDetailStatsScreen> {
  final TestService _testService = TestService();
  final ExerciseService _exerciseService = ExerciseService();

  PerformanceTest? _selectedTest;

  String _formatDuration(int seconds) {
    final m = (seconds / 60).floor();
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')} Min.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leistungstest-Auswertung: ${widget.playerName}'),
      ),
      body: StreamBuilder<List<PerformanceTest>>(
        stream: _testService.getTestTemplates(),
        builder: (context, testSnapshot) {
          if (testSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allTests = testSnapshot.data ?? [];

          if (allTests.isEmpty) {
            return const Center(
              child: Text('Noch keine Leistungstest-Vorlagen angelegt.'),
            );
          }

          // Standardmäßig den ersten Test auswählen
          _selectedTest ??= allTests.first;

          return StreamBuilder<List<Exercise>>(
            stream: _exerciseService.getExercises(),
            builder: (context, exerciseSnapshot) {
              final allExercises = exerciseSnapshot.data ?? [];

              // Übungen filtern, die zum gewählten Test gehören
              final currentTestExercises = allExercises
                  .where((e) => _selectedTest!.exerciseIds.contains(e.id))
                  .toList();

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // DROPDOWN FÜR LEISTUNGSTEST-AUSWAHL
                    const Text(
                      'Leistungstest auswählen:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<PerformanceTest>(
                          value: _selectedTest,
                          isExpanded: true,
                          items: allTests.map((t) {
                            return DropdownMenuItem(
                              value: t,
                              child: Text(t.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedTest = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // TABELLE DER GEFILTERTEN TESTERGEBNISSE
                    Text(
                      'Ergebnisse für "${_selectedTest!.title}"',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: StreamBuilder<List<PerformanceTestResult>>(
                        stream: _testService.getResultsForPlayerAndTest(
                          widget.playerId,
                          _selectedTest!.id,
                        ),
                        builder: (context, resultSnapshot) {
                          if (resultSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final results = resultSnapshot.data ?? [];

                          if (results.isEmpty) {
                            return const Center(
                              child: Text(
                                'Für diesen Leistungstest liegen noch keine Daten vor.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }

                          return Card(
                            elevation: 2,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                child: DataTable(
                                  headingRowColor: MaterialStateProperty.all(
                                      Colors.deepOrange.shade50),
                                  columns: [
                                    const DataColumn(
                                      label: Text('Datum',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    // SPALTEN FÜR JEDE ÜBUNG DES TESTS
                                    ...currentTestExercises.map((ex) {
                                      return DataColumn(
                                        label: Text(
                                          ex.title,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      );
                                    }),
                                    const DataColumn(
                                      label: Text('Gesamtpunkte',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    const DataColumn(
                                      label: Text('Gesamtdauer',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                  rows: results.map((res) {
                                    final dateFormatted =
                                        '${res.timestamp.day}.${res.timestamp.month}.${res.timestamp.year}';

                                    return DataRow(
                                      cells: [
                                        DataCell(Text(dateFormatted)),
                                        // PUNKTE JE ÜBUNG
                                        ...currentTestExercises.map((ex) {
                                          final score =
                                              res.exerciseScores[ex.id] ?? 0;
                                          return DataCell(Text('$score'));
                                        }),
                                        // GESAMTPUNKTE
                                        DataCell(
                                          Text(
                                            '${res.totalScore}',
                                            style: const TextStyle(
                                              color: Colors.deepOrange,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        // BENÖTIGTE ZEIT
                                        DataCell(
                                          Text(_formatDuration(
                                              res.durationInSeconds)),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}