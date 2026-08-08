import 'package:flutter/material.dart';
import '../models/performance_test_model.dart';
import '../models/exercise_model.dart';
import '../services/test_service.dart';
import '../services/exercise_service.dart';

/// Bildschirm zur geführten Durchführung eines Leistungstests durch den Spieler.
/// Die Zeit wird im Hintergrund ab dem Öffnen des Bildschirms automatisch gemessen.
class TakeTestScreen extends StatefulWidget {
  final PerformanceTest test;
  final String playerId;

  const TakeTestScreen({
    super.key,
    required this.test,
    required this.playerId,
  });

  @override
  State<TakeTestScreen> createState() => _TakeTestScreenState();
}

class _TakeTestScreenState extends State<TakeTestScreen> {
  final TestService _testService = TestService();
  final ExerciseService _exerciseService = ExerciseService();

  // SPEICHERT DIE EXAKTE STARTZEIT DES LEISTUNGSTESTS
  late DateTime _startTime;
  bool _isSaving = false;

  // Speichert die Text-Controller für die Punkteeingaben pro Übungs-ID
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    // 1. Startzeitpunkt genau beim Laden des Bildschirms festhalten
    _startTime = DateTime.now();

    // 2. Eingabefelder für jede Übung des Tests vorbereiten
    for (var exId in widget.test.exerciseIds) {
      _controllers[exId] = TextEditingController();
    }
  }

  @override
  void dispose() {
    // Speicherbereinigung der Controller
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Validiert die Eingaben, berechnet Punkte & Dauer und speichert das Ergebnis
  void _submitTest(List<Exercise> testExercises) async {
    final Map<String, int> scores = {};
    int calculatedTotalScore = 0;

    // Punkte aus allen Eingabefeldern auslesen & summieren
    for (var ex in testExercises) {
      final text = _controllers[ex.id]?.text.trim() ?? '';
      if (text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bitte Punkte für "${ex.title}" eingeben.')),
        );
        return;
      }
      final val = int.tryParse(text) ?? 0;
      scores[ex.id] = val;
      calculatedTotalScore += val;
    }

    setState(() => _isSaving = true);

    // BERECHNUNG DER BENÖTIGTEN ZEIT IN SEKUNDEN
    final endTime = DateTime.now();
    final durationInSeconds = endTime.difference(_startTime).inSeconds;

    final result = PerformanceTestResult(
      id: '',
      playerId: widget.playerId,
      testId: widget.test.id,
      testTitle: widget.test.title,
      exerciseScores: scores,
      totalScore: calculatedTotalScore,
      durationInSeconds: durationInSeconds,
      timestamp: DateTime.now(),
    );

    try {
      await _testService.saveTestResult(result);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Leistungstest abgegeben! Gesamtpunkte: $calculatedTotalScore (${(durationInSeconds / 60).floor()} Min. ${durationInSeconds % 60} Sek.)',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Speichern: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.test.title),
      ),
      body: StreamBuilder<List<Exercise>>(
        stream: _exerciseService.getExercises(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allExercises = snapshot.data ?? [];
          final testExercises = allExercises
              .where((e) => widget.test.exerciseIds.contains(e.id))
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // INFO-KARTEN ZUM TEST
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.deepOrange,
                          child: Icon(Icons.assignment, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.test.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (widget.test.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  widget.test.description,
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 13),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Übungen im Leistungstest',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // EINGABEFELDER PRO ÜBUNG
                ...testExercises.map((ex) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ex.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (ex.description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              ex.description,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          TextField(
                            controller: _controllers[ex.id],
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Punkte für ${ex.title}',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.score),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // ABGABE-BUTTON
                _isSaving
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: () => _submitTest(testExercises),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Test abschließen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}