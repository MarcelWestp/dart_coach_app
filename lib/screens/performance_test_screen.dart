import 'package:flutter/material.dart';
import '../models/performance_test_model.dart';
import '../models/exercise_model.dart'; // NEU: Import für Exercise
import '../services/test_service.dart';
import '../services/exercise_service.dart'; // NEU: Import für ExerciseService

/// Übersichtsbildschirm für Leistungstests (Erstellung & Vorschau für Trainer)
class PerformanceTestScreen extends StatefulWidget {
  const PerformanceTestScreen({super.key});

  @override
  State<PerformanceTestScreen> createState() => _PerformanceTestScreenState();
}

class _PerformanceTestScreenState extends State<PerformanceTestScreen> {
  final TestService _testService = TestService();
  final ExerciseService _exerciseService = ExerciseService();

  /// Dialog zum Anlegen einer neuen Testvorlage (mit Übungs-Auswahl)
  void _showCreateTestDialog(List<Exercise> availableExercises) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final List<String> selectedExerciseIds = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Neuen Leistungstest anlegen'),
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
                      }).toList(),
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
                                'Bitte einen Titel eingeben und mindestens eine Übung auswählen.')),
                      );
                      return;
                    }

                    final newTest = PerformanceTest(
                      id: '',
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                      exerciseIds: selectedExerciseIds,
                    );

                    await _testService.createTestTemplate(newTest);
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Erstellen'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Exercise>>(
      stream: _exerciseService.getExercises(),
      builder: (context, exerciseSnapshot) {
        final availableExercises = exerciseSnapshot.data ?? [];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Leistungstests verwalten'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Neuen Test anlegen',
                onPressed: () => _showCreateTestDialog(availableExercises),
              ),
            ],
          ),
          body: StreamBuilder<List<PerformanceTest>>(
            stream: _testService.getTestTemplates(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final tests = snapshot.data ?? [];

              if (tests.isEmpty) {
                return const Center(
                  child: Text(
                    'Noch keine Leistungstests angelegt.\nKlicke oben auf "+", um einen neuen Test zu erstellen.',
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
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}