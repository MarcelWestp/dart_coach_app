import 'package:flutter/material.dart';
import '../../models/weekly_plan_model.dart';
import '../../services/plan_service.dart';

/// Ein eigenständiger Dialog zum Bearbeiten der Trainer-Notiz einer geplante Übung.
class EditTrainerNoteDialog extends StatefulWidget {
  final TrainingPlan currentPlan;
  final String dayName;
  final ScheduledExercise scheduledEx;
  final String exerciseTitle;

  const EditTrainerNoteDialog({
    super.key,
    required this.currentPlan,
    required this.dayName,
    required this.scheduledEx,
    required this.exerciseTitle,
  });

  @override
  State<EditTrainerNoteDialog> createState() => _EditTrainerNoteDialogState();
}

class _EditTrainerNoteDialogState extends State<EditTrainerNoteDialog> {
  final PlanService _planService = PlanService();
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    // Vorbefüllen des Textfelds mit der bereits bestehenden Notiz
    _noteController = TextEditingController(text: widget.scheduledEx.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final String? newNote = _noteController.text.trim().isNotEmpty
        ? _noteController.text.trim()
        : null;

    // Aktualisieren des Tagesplans im TrainingPlan
    final updatedDays = widget.currentPlan.days.map((d) {
      if (d.dayOfWeek == widget.dayName) {
        final updatedExercises = d.scheduledExercises.map((se) {
          if (se.exerciseId == widget.scheduledEx.exerciseId) {
            return ScheduledExercise(
              exerciseId: se.exerciseId,
              targetType: se.targetType,
              targetValue: se.targetValue,
              note: newNote,
            );
          }
          return se;
        }).toList();

        return DailySchedule(
          dayOfWeek: d.dayOfWeek,
          scheduledExercises: updatedExercises,
        );
      }
      return d;
    }).toList();

    final updatedPlan = TrainingPlan(
      id: widget.currentPlan.id,
      title: widget.currentPlan.title,
      playerId: widget.currentPlan.playerId,
      trainerId: widget.currentPlan.trainerId,
      year: widget.currentPlan.year,
      weekNumber: widget.currentPlan.weekNumber,
      days: updatedDays,
    );

    await _planService.saveTrainingPlan(updatedPlan);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trainer-Notiz erfolgreich gespeichert!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Trainer-Notiz bearbeiten',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.exerciseTitle} (${widget.dayName})',
            style: TextStyle(
              fontSize: 14,
              color: Colors.deepOrange.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Hinweis / Anweisung für den Spieler',
                hintText: 'z. B. Fokus auf die Haltung beim Abwurf legen...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _saveNote,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}