import 'package:flutter/material.dart';
import '../models/performance_test_model.dart';
import '../models/exercise_model.dart';
import '../services/test_service.dart';
import '../services/exercise_service.dart';

/// Spezialisierter Statistik-Bildschirm für Leistungstests mit dynamischen Spalten
/// und Notiz-Einsehen/Bearbeiten-Funktion.
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

  /// Formatiert Sekunden in MM:SS Min.
  String _formatDuration(int seconds) {
    final m = (seconds / 60).floor();
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')} Min.';
  }

  /// Öffnet einen Dialog zum Einsehen und Bearbeiten der Notiz
  void _showNoteDialog(PerformanceTestResult result) {
    final noteController = TextEditingController(text: result.note ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.note_alt_outlined, color: Colors.deepOrange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Notiz: ${result.testTitle}',
                  style: const TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Datum: ${result.timestamp.day}.${result.timestamp.month}.${result.timestamp.year}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Spielernotiz / Anmerkungen',
                  hintText: 'Keine Notiz vorhanden. Hier tippen, um eine hinzuzufügen...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedText = noteController.text.trim();
                final updatedResult = result.copyWith(
                  note: updatedText.isNotEmpty ? updatedText : null,
                );

                try {
                  await _testService.updateTestResult(updatedResult);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notiz erfolgreich gespeichert!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Fehler beim Speichern: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );
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
                              child: Text(
                                t.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
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
                                    // NEU: SPALTE FÜR DIE NOTIZ
                                    const DataColumn(
                                      label: Text('Notiz',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                  rows: results.map((res) {
                                    final dateFormatted =
                                        '${res.timestamp.day}.${res.timestamp.month}.${res.timestamp.year}';

                                    final bool hasNote = res.note != null &&
                                        res.note!.trim().isNotEmpty;

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
                                        // NEU: DATA-CELL FÜR NOTIZ ANZEIGEN & EDITIEREN
                                        DataCell(
                                          InkWell(
                                            onTap: () => _showNoteDialog(res),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 4.0,
                                                      horizontal: 8.0),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    hasNote
                                                        ? Icons.sticky_note_2
                                                        : Icons
                                                            .add_comment_outlined,
                                                    size: 18,
                                                    color: hasNote
                                                        ? Colors.deepOrange
                                                        : Colors.grey,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    hasNote
                                                        ? (res.note!.length > 15
                                                            ? '${res.note!.substring(0, 15)}...'
                                                            : res.note!)
                                                        : 'Hinzufügen',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: hasNote
                                                          ? Colors.black87
                                                          : Colors.grey,
                                                      fontStyle: hasNote
                                                          ? FontStyle.normal
                                                          : FontStyle.italic,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
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