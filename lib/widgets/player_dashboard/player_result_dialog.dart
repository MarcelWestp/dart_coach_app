import 'package:flutter/material.dart';
import '../../models/exercise_model.dart';
import '../../models/result_model.dart';
import '../../models/weekly_plan_model.dart';
import '../../services/result_service.dart';

/// Ein eigenständiger Dialog zur Eingabe und Korrektur von Spieler-Ergebnissen
/// inklusive Unterstützung für multiple Durchläufe, Trainer-Hinweise und Spieler-Notizen.
class PlayerResultDialog extends StatefulWidget {
  final Exercise exercise;
  final String userId;
  final String dayName;
  final int currentWeekNumber;
  final int currentYear;
  final TargetType targetType;
  final String targetValue;
  final String? trainerNote;
  final List<ExerciseResult>? existingResults;

  const PlayerResultDialog({
    super.key,
    required this.exercise,
    required this.userId,
    required this.dayName,
    required this.currentWeekNumber,
    required this.currentYear,
    this.targetType = TargetType.none,
    this.targetValue = '',
    this.trainerNote,
    this.existingResults,
  });

  @override
  State<PlayerResultDialog> createState() => _PlayerResultDialogState();
}

class _PlayerResultDialogState extends State<PlayerResultDialog> {
  final ResultService _resultService = ResultService();

  late int _repsCount;
  late TextEditingController _playerNoteController;

  final List<TextEditingController> _scoreControllers = [];
  final List<TextEditingController> _hitsControllers = [];
  final List<TextEditingController> _attemptsControllers = [];
  final List<TextEditingController> _timeControllers = [];

  @override
  void initState() {
    super.initState();
    _repsCount = _parseRepsCount(widget.targetType, widget.targetValue);

    _playerNoteController = TextEditingController(
      text: widget.existingResults?.firstOrNull?.playerNote ?? '',
    );

    for (int i = 0; i < _repsCount; i++) {
      final existing = widget.existingResults?.firstWhere(
        (r) => r.roundIndex == (i + 1),
        orElse: () =>
            widget.existingResults != null && widget.existingResults!.length > i
            ? widget.existingResults![i]
            : ExerciseResult(
                id: '',
                playerId: '',
                exerciseId: '',
                timestamp: DateTime.now(),
              ),
      );

      _scoreControllers.add(
        TextEditingController(text: existing?.score?.toString() ?? ''),
      );
      _hitsControllers.add(
        TextEditingController(text: existing?.hits?.toString() ?? ''),
      );
      _attemptsControllers.add(
        TextEditingController(text: existing?.attempts?.toString() ?? ''),
      );
      _timeControllers.add(
        TextEditingController(text: existing?.timeInSeconds?.toString() ?? ''),
      );
    }
  }

  @override
  void dispose() {
    _playerNoteController.dispose();
    for (var c in _scoreControllers) {
      c.dispose();
    }
    for (var c in _hitsControllers) {
      c.dispose();
    }
    for (var c in _attemptsControllers) {
      c.dispose();
    }
    for (var c in _timeControllers) {
      c.dispose();
    }
    super.dispose();
  }

  /// Liest die Anzahl der Durchläufe aus dem Vorgabe-Text aus (z. B. "3 Serien" -> 3)
  int _parseRepsCount(TargetType targetType, String targetValue) {
    if (targetType != TargetType.reps || targetValue.trim().isEmpty) {
      return 1;
    }
    final RegExp regExp = RegExp(r'\d+');
    final match = regExp.firstMatch(targetValue);
    if (match != null) {
      return int.tryParse(match.group(0)!) ?? 1;
    }
    return 1;
  }

  Future<void> _saveResults() async {
    final String? noteText = _playerNoteController.text.trim().isNotEmpty
        ? _playerNoteController.text.trim()
        : null;

    for (int i = 0; i < _repsCount; i++) {
      final scoreVal = int.tryParse(_scoreControllers[i].text.trim());
      final hitsVal = int.tryParse(_hitsControllers[i].text.trim());
      final attemptsVal = int.tryParse(_attemptsControllers[i].text.trim());
      final timeVal = int.tryParse(_timeControllers[i].text.trim());

      if (scoreVal != null || hitsVal != null || timeVal != null) {
        final newResult = ExerciseResult(
          id: '',
          playerId: widget.userId,
          exerciseId: widget.exercise.id,
          timestamp: DateTime.now(),
          score: scoreVal,
          hits: hitsVal,
          attempts: attemptsVal,
          timeInSeconds: timeVal,
          dayOfWeek: widget.dayName,
          weekNumber: widget.currentWeekNumber,
          year: widget.currentYear,
          roundIndex: _repsCount > 1 ? (i + 1) : null,
          playerNote: noteText,
        );

        await _resultService.saveResult(newResult);
      }
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _repsCount > 1
                ? '$_repsCount Durchläufe für ${widget.dayName} gespeichert!'
                : 'Ergebnis für ${widget.dayName} gespeichert!',
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
            _repsCount > 1
                ? 'Ergebnisse eintragen ($_repsCount Durchläufe)'
                : 'Ergebnis eintragen',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.exercise.title} (${widget.dayName})',
            style: TextStyle(
              fontSize: 15,
              color: Colors.deepOrange.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TRAINER-HINWEIS
              if (widget.trainerNote != null &&
                  widget.trainerNote!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.sports_rounded,
                        size: 18,
                        color: Colors.amber.shade900,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Trainer-Hinweis:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.trainerNote!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // BESCHREIBUNG DER ÜBUNG
              if (widget.exercise.description.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    widget.exercise.description,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // DURCHLÄUFE-SCHLEIFE
              for (int i = 0; i < _repsCount; i++) ...[
                if (_repsCount > 1) ...[
                  Text(
                    'Durchlauf ${i + 1} von $_repsCount:',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                if (widget.exercise.metricType == MetricType.score)
                  TextField(
                    controller: _scoreControllers[i],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: _repsCount > 1
                          ? 'Score Durchlauf ${i + 1}'
                          : 'Erzielte Punkte / Score',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                if (widget.exercise.metricType == MetricType.hits)
                  TextField(
                    controller: _hitsControllers[i],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: _repsCount > 1
                          ? 'Treffer Durchlauf ${i + 1}'
                          : 'Anzahl Treffer',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),

                // EINGABEFELD: NUR VERSUCHE
                if (widget.exercise.metricType == MetricType.attempts)
                  TextField(
                    controller: _attemptsControllers[i],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: _repsCount > 1
                          ? 'Benötigte Versuche Durchlauf ${i + 1}'
                          : 'Anzahl benötigter Versuche',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                if (widget.exercise.metricType == MetricType.timeInSeconds)
                  TextField(
                    controller: _timeControllers[i],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: _repsCount > 1
                          ? 'Zeit in Sek. (Durchlauf ${i + 1})'
                          : 'Zeit in Sekunden',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                const SizedBox(height: 16),
              ],

              // SPIELER-BEMERKUNG
              const Divider(),
              const SizedBox(height: 8),
              TextField(
                controller: _playerNoteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Eigene Bemerkung / Feedback (optional)',
                  hintText: 'z. B. Gutes Gefühl, Darts lagen eng zusammen...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _saveResults,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
