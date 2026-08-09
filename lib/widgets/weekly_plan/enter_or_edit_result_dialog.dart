import 'package:flutter/material.dart';
import '../../models/exercise_model.dart';
import '../../models/result_model.dart';
import '../../services/result_service.dart';

/// Ein eigenständiger Dialog zum Eintragen oder Korrigieren eines Übungsergebnisses.
class EnterOrEditResultDialog extends StatefulWidget {
  final Exercise exercise;
  final String targetPlayerId;
  final ExerciseResult? existingResult;

  const EnterOrEditResultDialog({
    super.key,
    required this.exercise,
    required this.targetPlayerId,
    this.existingResult,
  });

  @override
  State<EnterOrEditResultDialog> createState() =>
      _EnterOrEditResultDialogState();
}

class _EnterOrEditResultDialogState extends State<EnterOrEditResultDialog> {
  final ResultService _resultService = ResultService();

  late TextEditingController _scoreController;
  late TextEditingController _hitsController;
  late TextEditingController _attemptsController;
  late TextEditingController _timeController;

  bool get _isEditing => widget.existingResult != null;

  @override
  void initState() {
    super.initState();
    // Vorbefüllen der Controller mit bestehenden Werten (falls vorhanden)
    _scoreController = TextEditingController(
      text: widget.existingResult?.score?.toString() ?? '',
    );
    _hitsController = TextEditingController(
      text: widget.existingResult?.hits?.toString() ?? '',
    );
    _attemptsController = TextEditingController(
      text: widget.existingResult?.attempts?.toString() ?? '',
    );
    _timeController = TextEditingController(
      text: widget.existingResult?.timeInSeconds?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _hitsController.dispose();
    _attemptsController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  /// Speichert ein neues Ergebnis oder aktualisiert ein bestehendes in Firestore
  Future<void> _saveResult() async {
    final newResult = ExerciseResult(
      id: _isEditing ? widget.existingResult!.id : '',
      playerId: widget.targetPlayerId,
      exerciseId: widget.exercise.id,
      timestamp: _isEditing ? widget.existingResult!.timestamp : DateTime.now(),
      score: int.tryParse(_scoreController.text.trim()),
      hits: int.tryParse(_hitsController.text.trim()),
      attempts: int.tryParse(_attemptsController.text.trim()),
      timeInSeconds: int.tryParse(_timeController.text.trim()),
    );

    if (_isEditing) {
      await _resultService.updateResult(newResult);
    } else {
      await _resultService.saveResult(newResult);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Ergebnis erfolgreich korrigiert!'
                : 'Ergebnis gespeichert!',
          ),
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
          Text(
            _isEditing ? 'Ergebnis korrigieren' : 'Ergebnis eintragen',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            widget.exercise.title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ANLEITUNG / BESCHREIBUNG (falls vorhanden)
            if (widget.exercise.description.isNotEmpty) ...[
              Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Anleitung / Beschreibung:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.exercise.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // EINGABEFELD: SCORE / PUNKTE
            if (widget.exercise.metricType == MetricType.score)
              TextField(
                controller: _scoreController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Erzielte Punkte / Score',
                  border: OutlineInputBorder(),
                ),
              ),

            // EINGABEFELD: NUR TREFFER
            if (widget.exercise.metricType == MetricType.hits)
              TextField(
                controller: _hitsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Anzahl Treffer',
                  border: OutlineInputBorder(),
                ),
              ),

            // EINGABEFELD: NUR VERSUCHE
            if (widget.exercise.metricType == MetricType.attempts)
              TextField(
                controller: _attemptsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Anzahl benötigter Versuche',
                  border: OutlineInputBorder(),
                ),
              ),

            // EINGABEFELD: ZEIT IN SEKUNDEN
            if (widget.exercise.metricType == MetricType.timeInSeconds)
              TextField(
                controller: _timeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Zeit in Sekunden',
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
          onPressed: _saveResult,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isEditing ? Colors.orange : Colors.green,
            foregroundColor: Colors.white,
          ),
          child: Text(_isEditing ? 'Aktualisieren' : 'Speichern'),
        ),
      ],
    );
  }
}
