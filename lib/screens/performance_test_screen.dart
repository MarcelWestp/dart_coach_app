import 'package:flutter/material.dart';
import '../models/performance_test_model.dart';
import '../models/exercise_model.dart';
import '../services/test_service.dart';
import '../services/exercise_service.dart';

/// Übersichtsbildschirm für Leistungstests (Erstellung, Bearbeitung & Vorschau für Trainer).
/// Fügt sich ohne doppeltes Scaffold/AppBar nahtlos in den TrainerMainScreen ein.
class PerformanceTestScreen extends StatefulWidget {
  const PerformanceTestScreen({super.key});

  @override
  State<PerformanceTestScreen> createState() => _PerformanceTestScreenState();
}

class _PerformanceTestScreenState extends State<PerformanceTestScreen> {
  final TestService _testService = TestService();
  final ExerciseService _exerciseService = ExerciseService();

  /// Kombinierter Dialog zum Anlegen ODERE Bearbeiten einer Testvorlage
  void _showTestDialog(
    List<Exercise> availableExercises, {
    PerformanceTest? existingTest,
  }) {
    final bool isEditing = existingTest != null;
    final titleController = TextEditingController(
      text: isEditing ? existingTest.title : '',
    );
    final descController = TextEditingController(
      text: isEditing ? existingTest.description : '',
    );

    // Vorausgewählte Übungs-IDs übernehmen (falls Bearbeitung)
    final List<String> selectedExerciseIds = isEditing
        ? List<String>.from(existingTest.exerciseIds)
        : [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEditing ? 'Leistungstest bearbeiten' : 'Neuen Leistungstest anlegen',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Titel (z. B. BDC Leistungsdiagnostik)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Beschreibung / Anleitung',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Übungen im Test:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    if (availableExercises.isEmpty)
                      const Text(
                        'Keine Übungen vorhanden. Bitte zuerst unter "Übungen verwalten" Übungen anlegen.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      )
                    else
                      ...availableExercises.map((ex) {
                        final isChecked = selectedExerciseIds.contains(ex.id);
                        return CheckboxListTile(
                          title: Text(ex.title),
                          subtitle: Text('Typ: ${ex.metricType.name}'),
                          value: isChecked,
                          activeColor: Colors.deepOrange,
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == true) {
                                selectedExerciseIds.add(ex.id);
                              } else {
                                selectedExerciseIds.remove(ex.id);
                              }
                            });
                          },
                        );
                      }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Abbrechen'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty ||
                        selectedExerciseIds.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Bitte einen Titel eingeben und mindestens eine Übung auswählen.',
                          ),
                        ),
                      );
                      return;
                    }

                    final testData = PerformanceTest(
                      id: isEditing ? existingTest.id : '',
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                      exerciseIds: selectedExerciseIds,
                    );

                    if (isEditing) {
                      await _testService.updateTestTemplate(testData);
                    } else {
                      await _testService.createTestTemplate(testData);
                    }

                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isEditing ? 'Speichern' : 'Erstellen'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Sicherheitsdialog zum Löschen einer Testvorlage
  void _confirmDeleteTest(PerformanceTest test) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leistungstest löschen?'),
        content: Text(
          'Möchtest du den Leistungstest "${test.title}" wirklich löschen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _testService.deleteTestTemplate(test.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Exercise>>(
      stream: _exerciseService.getExercises(),
      builder: (context, exerciseSnapshot) {
        final availableExercises = exerciseSnapshot.data ?? [];

        return Column(
          children: [
            // AKTIONSLEISTE OBEN (Button zum Anlegen neuer Leistungstests)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              color: Theme.of(context).cardColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Verfügbare Testvorlagen',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Neuer Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _showTestDialog(availableExercises),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // LISTE DER LEISTUNGSTESTS
            Expanded(
              child: StreamBuilder<List<PerformanceTest>>(
                stream: _testService.getTestTemplates(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.deepOrange),
                    );
                  }

                  final tests = snapshot.data ?? [];

                  if (tests.isEmpty) {
                    return const Center(
                      child: Text(
                        'Noch keine Leistungstests angelegt.\nKlicke oben auf "Neuer Test", um eine Vorlage zu erstellen.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: tests.length,
                    itemBuilder: (context, index) {
                      final test = tests[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.deepOrange,
                            child: Icon(Icons.assignment, color: Colors.white),
                          ),
                          title: Text(
                            test.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${test.description}\nAnzahl Übungen: ${test.exerciseIds.length}',
                          ),
                          isThreeLine: true,
                          // AKTIONEN: BEARBEITEN & LÖSCHEN
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                tooltip: 'Bearbeiten',
                                onPressed: () => _showTestDialog(
                                  availableExercises,
                                  existingTest: test,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                tooltip: 'Löschen',
                                onPressed: () => _confirmDeleteTest(test),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}