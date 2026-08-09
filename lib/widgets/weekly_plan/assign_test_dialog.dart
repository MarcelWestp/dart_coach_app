import 'package:flutter/material.dart';
import '../../models/performance_test_model.dart';
import '../../services/test_service.dart';

/// Ein eigenständiger Dialog, der dem Trainer die Liste aller verfügbaren
/// Leistungstests anzeigt und das Zuweisen für eine bestimmte Kalenderwoche durchführt.
class AssignTestDialog extends StatelessWidget {
  final List<PerformanceTest> availableTests;
  final String targetPlayerId;
  final String currentTrainerId;
  final int year;
  final int weekNumber;

  // Der TestService wird zur Speicherung in Firestore verwendet
  final TestService _testService = TestService();

  AssignTestDialog({
    super.key,
    required this.availableTests,
    required this.targetPlayerId,
    required this.currentTrainerId,
    required this.year,
    required this.weekNumber,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Leistungstest für KW $weekNumber zuweisen'),
      content: availableTests.isEmpty
          ? const Text(
              'Keine Leistungstest-Vorlagen vorhanden. Bitte zuerst unter "Leistungstests" anlegen.',
            )
          : SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: availableTests.length,
                itemBuilder: (context, index) {
                  final test = availableTests[index];
                  return ListTile(
                    leading: const Icon(
                      Icons.assignment,
                      color: Colors.deepOrange,
                    ),
                    title: Text(test.title),
                    subtitle: Text(
                      'Enthaltene Übungen: ${test.exerciseIds.length}',
                    ),
                    onTap: () async {
                      // Erstellen des Zuweisungsobjekts
                      final assignment = AssignedTest(
                        id: '',
                        playerId: targetPlayerId,
                        trainerId: currentTrainerId,
                        testId: test.id,
                        year: year,
                        weekNumber: weekNumber,
                      );

                      // Speichern über den TestService
                      await _testService.assignTestToPlayer(assignment);

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Test "${test.title}" zugewiesen!',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
      ],
    );
  }
}