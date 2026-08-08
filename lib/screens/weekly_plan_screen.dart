import 'package:flutter/material.dart';
import '../models/exercise_model.dart';
import '../models/result_model.dart';
import '../models/weekly_plan_model.dart';
import '../models/performance_test_model.dart';
import '../models/tag_model.dart';
import '../services/exercise_service.dart';
import '../services/plan_service.dart';
import '../services/result_service.dart';
import '../services/test_service.dart';
import '../services/tag_service.dart';
import 'exercise_history_screen.dart';
import 'take_test_screen.dart';

/// Wochenansicht mit integrierter Leistungstest-Zuweisung, Tag-Filtern und Vorgaben
class WeeklyPlanScreen extends StatefulWidget {
  final String targetPlayerId;
  final bool isTrainer;

  const WeeklyPlanScreen({
    super.key,
    required this.targetPlayerId,
    required this.isTrainer,
  });

  @override
  State<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends State<WeeklyPlanScreen> {
  final PlanService _planService = PlanService();
  final ExerciseService _exerciseService = ExerciseService();
  final ResultService _resultService = ResultService();
  final TestService _testService = TestService();
  final TagService _tagService = TagService();

  late DateTime _selectedDate;
  late int _currentWeekNumber;
  late int _currentYear;

  final List<String> _daysOfWeek = [
    'Montag',
    'Dienstag',
    'Mittwoch',
    'Donnerstag',
    'Freitag',
    'Samstag',
    'Sonntag'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _updateWeekAndYear();
  }

  void _updateWeekAndYear() {
    int w = ((_selectedDate.difference(DateTime(_selectedDate.year, 1, 1)).inDays + 1) / 7).ceil();
    _currentWeekNumber = w > 52 ? 52 : (w == 0 ? 1 : w);
    _currentYear = _selectedDate.year;
  }

  void _changeWeek(int weeksToAdd) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: weeksToAdd * 7));
      _updateWeekAndYear();
    });
  }

  /// Dialog für Trainer zur Zuweisung eines Leistungstests für die aktuelle KW
  void _showAssignTestDialog(List<PerformanceTest> availableTests, String currentTrainerId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Leistungstest für KW $_currentWeekNumber zuweisen'),
          content: availableTests.isEmpty
              ? const Text('Keine Leistungstest-Vorlagen vorhanden. Bitte zuerst unter "Leistungstests" anlegen.')
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: availableTests.length,
                    itemBuilder: (context, index) {
                      final test = availableTests[index];
                      return ListTile(
                        leading: const Icon(Icons.assignment, color: Colors.deepOrange),
                        title: Text(test.title),
                        subtitle: Text('Enthaltene Übungen: ${test.exerciseIds.length}'),
                        onTap: () async {
                          final assignment = AssignedTest(
                            id: '',
                            playerId: widget.targetPlayerId,
                            trainerId: currentTrainerId,
                            testId: test.id,
                            year: _currentYear,
                            weekNumber: _currentWeekNumber,
                          );

                          await _testService.assignTestToPlayer(assignment);

                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Test "${test.title}" zugewiesen!')),
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
      },
    );
  }

  /// Dialog zum Eintragen oder Korrigieren eines Ergebnisses
  void _showEnterOrEditResultDialog(Exercise exercise, {ExerciseResult? existingResult}) {
    final scoreController = TextEditingController(
      text: existingResult?.score?.toString() ?? '',
    );
    final hitsController = TextEditingController(
      text: existingResult?.hits?.toString() ?? '',
    );
    final attemptsController = TextEditingController(
      text: existingResult?.attempts?.toString() ?? '',
    );
    final timeController = TextEditingController(
      text: existingResult?.timeInSeconds?.toString() ?? '',
    );

    final bool isEditing = existingResult != null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEditing ? 'Ergebnis korrigieren' : 'Ergebnis eintragen',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                exercise.title,
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
                if (exercise.description.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
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
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          exercise.description,
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (exercise.metricType == MetricType.score)
                  TextField(
                    controller: scoreController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Erzielte Punkte / Score',
                      border: OutlineInputBorder(),
                    ),
                  ),
                if (exercise.metricType == MetricType.hitsAndAttempts) ...[
                  TextField(
                    controller: hitsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Anzahl Treffer',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: attemptsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Anzahl Versuche',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                if (exercise.metricType == MetricType.timeInSeconds)
                  TextField(
                    controller: timeController,
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
              onPressed: () async {
                final newResult = ExerciseResult(
                  id: isEditing ? existingResult.id : '',
                  playerId: widget.targetPlayerId,
                  exerciseId: exercise.id,
                  timestamp: isEditing ? existingResult.timestamp : DateTime.now(),
                  score: int.tryParse(scoreController.text.trim()),
                  hits: int.tryParse(hitsController.text.trim()),
                  attempts: int.tryParse(attemptsController.text.trim()),
                  timeInSeconds: int.tryParse(timeController.text.trim()),
                );

                if (isEditing) {
                  await _resultService.updateResult(newResult);
                } else {
                  await _resultService.saveResult(newResult);
                }

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEditing
                            ? 'Ergebnis erfolgreich korrigiert!'
                            : 'Ergebnis gespeichert!',
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isEditing ? Colors.orange : Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'Aktualisieren' : 'Speichern'),
            ),
          ],
        );
      },
    );
  }

  /// Bearbeiten der Tagesübungen inklusive Tag-Filter und Dauer/Wiederholungs-Vorgabe
  void _editDaySchedule(
    TrainingPlan currentPlan,
    String dayName,
    List<Exercise> availableExercises,
  ) {
    final daySchedule = currentPlan.days.firstWhere(
      (d) => d.dayOfWeek == dayName,
      orElse: () => DailySchedule(dayOfWeek: dayName, scheduledExercises: []),
    );

    final Map<String, ScheduledExercise> selectedMap = {
      for (var se in daySchedule.scheduledExercises) se.exerciseId: se
    };

    String? selectedFilterTagId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return StreamBuilder<List<ExerciseTag>>(
              stream: _tagService.getTags(),
              builder: (context, tagSnapshot) {
                final tags = tagSnapshot.data ?? [];

                final filteredExercises = selectedFilterTagId == null
                    ? availableExercises
                    : availableExercises
                        .where((e) => e.tagIds.contains(selectedFilterTagId))
                        .toList();

                return AlertDialog(
                  title: Text('Übungen für $dayName (KW $_currentWeekNumber)'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (tags.isNotEmpty) ...[
                            const Text('Nach Tag filtern:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 6),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ChoiceChip(
                                    label: const Text('Alle'),
                                    selected: selectedFilterTagId == null,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setDialogState(() => selectedFilterTagId = null);
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  ...tags.map((tag) {
                                    final isSelected = selectedFilterTagId == tag.id;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 6.0),
                                      child: ChoiceChip(
                                        label: Text(tag.name),
                                        selected: isSelected,
                                        selectedColor: tag.color.withOpacity(0.3),
                                        onSelected: (selected) {
                                          setDialogState(() {
                                            selectedFilterTagId = selected ? tag.id : null;
                                          });
                                        },
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const Divider(),
                          ],

                          ...filteredExercises.map((ex) {
                            final isSelected = selectedMap.containsKey(ex.id);
                            final currentScheduled = selectedMap[ex.id] ??
                                ScheduledExercise(exerciseId: ex.id);

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              elevation: isSelected ? 2 : 0,
                              color: isSelected ? Colors.deepOrange.shade50 : null,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    CheckboxListTile(
                                      dense: true,
                                      title: Text(ex.title,
                                          style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text(ex.description,
                                          maxLines: 1, overflow: TextOverflow.ellipsis),
                                      value: isSelected,
                                      activeColor: Colors.deepOrange,
                                      onChanged: (val) {
                                        setDialogState(() {
                                          if (val == true) {
                                            selectedMap[ex.id] = ScheduledExercise(exerciseId: ex.id);
                                          } else {
                                            selectedMap.remove(ex.id);
                                          }
                                        });
                                      },
                                    ),
                                    if (isSelected) ...[
                                      const Divider(height: 1),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12.0, vertical: 8.0),
                                        child: Row(
                                          children: [
                                            DropdownButton<TargetType>(
                                              value: currentScheduled.targetType,
                                              underline: const SizedBox(),
                                              items: const [
                                                DropdownMenuItem(
                                                  value: TargetType.none,
                                                  child: Text('Ohne Vorgabe'),
                                                ),
                                                DropdownMenuItem(
                                                  value: TargetType.duration,
                                                  child: Text('⏱️ Dauer'),
                                                ),
                                                DropdownMenuItem(
                                                  value: TargetType.reps,
                                                  child: Text('🔁 Durchgänge'),
                                                ),
                                              ],
                                              onChanged: (newType) {
                                                if (newType != null) {
                                                  setDialogState(() {
                                                    selectedMap[ex.id] = ScheduledExercise(
                                                      exerciseId: ex.id,
                                                      targetType: newType,
                                                      targetValue: currentScheduled.targetValue,
                                                    );
                                                  });
                                                }
                                              },
                                            ),
                                            const SizedBox(width: 8),
                                            if (currentScheduled.targetType != TargetType.none)
                                              Expanded(
                                                child: TextField(
                                                  controller: TextEditingController(
                                                    text: currentScheduled.targetValue,
                                                  )..selection = TextSelection.collapsed(
                                                      offset: currentScheduled.targetValue.length),
                                                  decoration: InputDecoration(
                                                    hintText: currentScheduled.targetType ==
                                                            TargetType.duration
                                                        ? 'z. B. 15 Min'
                                                        : 'z. B. 5 Sätze',
                                                    isDense: true,
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                            horizontal: 8, vertical: 8),
                                                    border: const OutlineInputBorder(),
                                                  ),
                                                  onChanged: (val) {
                                                    selectedMap[ex.id] = ScheduledExercise(
                                                      exerciseId: ex.id,
                                                      targetType: currentScheduled.targetType,
                                                      targetValue: val,
                                                    );
                                                  },
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
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
                      onPressed: () async {
                        final updatedDays = _daysOfWeek.map((day) {
                          if (day == dayName) {
                            return DailySchedule(
                              dayOfWeek: day,
                              scheduledExercises: selectedMap.values.toList(),
                            );
                          }
                          return currentPlan.days.firstWhere(
                            (d) => d.dayOfWeek == day,
                            orElse: () => DailySchedule(
                                dayOfWeek: day, scheduledExercises: []),
                          );
                        }).toList();

                        final updatedPlan = TrainingPlan(
                          id: currentPlan.id,
                          title: 'Wochenplan KW $_currentWeekNumber',
                          playerId: widget.targetPlayerId,
                          trainerId: currentPlan.trainerId,
                          year: _currentYear,
                          weekNumber: _currentWeekNumber,
                          days: updatedDays,
                        );

                        await _planService.saveTrainingPlan(updatedPlan);
                        if (mounted) Navigator.pop(context);
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
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wochen-Trainingsplan'),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.deepOrange.shade50,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () => _changeWeek(-1),
                ),
                Text(
                  'Kalenderwoche $_currentWeekNumber ($_currentYear)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () => _changeWeek(1),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<PerformanceTest>>(
              stream: _testService.getTestTemplates(),
              builder: (context, testTemplatesSnapshot) {
                final allTests = testTemplatesSnapshot.data ?? [];

                return StreamBuilder<AssignedTest?>(
                  stream: _testService.getAssignedTestForWeek(
                    widget.targetPlayerId,
                    _currentYear,
                    _currentWeekNumber,
                  ),
                  builder: (context, assignedTestSnapshot) {
                    final assignedTest = assignedTestSnapshot.data;
                    final PerformanceTest? currentWeekTest = assignedTest != null
                        ? allTests.firstWhere(
                            (t) => t.id == assignedTest.testId,
                            orElse: () => PerformanceTest(
                              id: '',
                              title: 'Unbekannter Test',
                              description: '',
                              exerciseIds: [],
                            ),
                          )
                        : null;

                    return StreamBuilder<List<Exercise>>(
                      stream: _exerciseService.getExercises(),
                      builder: (context, exerciseSnapshot) {
                        final exercises = exerciseSnapshot.data ?? [];

                        return StreamBuilder<List<ExerciseResult>>(
                          stream: _resultService
                              .getResultsForPlayer(widget.targetPlayerId),
                          builder: (context, resultSnapshot) {
                            final allResults = resultSnapshot.data ?? [];

                            return StreamBuilder<TrainingPlan?>(
                              stream: _planService.getPlanForPlayerAndWeek(
                                widget.targetPlayerId,
                                _currentYear,
                                _currentWeekNumber,
                              ),
                              builder: (context, planSnapshot) {
                                if (planSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }

                                final plan = planSnapshot.data ??
                                    TrainingPlan(
                                      id: '',
                                      title: 'Wochenplan',
                                      playerId: widget.targetPlayerId,
                                      trainerId: '',
                                      year: _currentYear,
                                      weekNumber: _currentWeekNumber,
                                      days: _daysOfWeek
                                          .map((d) => DailySchedule(
                                              dayOfWeek: d, scheduledExercises: []))
                                          .toList(),
                                    );

                                return ListView(
                                  padding: const EdgeInsets.all(12),
                                  children: [
                                    // KACHEL: LEISTUNGSTEST DER WOCHE
                                    Card(
                                      color: Colors.deepOrange.shade100,
                                      elevation: 3,
                                      margin: const EdgeInsets.only(bottom: 16),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Row(
                                                  children: [
                                                    Icon(Icons.assignment,
                                                        color: Colors.deepOrange),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Wochen-Leistungstest',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.deepOrange,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (widget.isTrainer)
                                                  ElevatedButton.icon(
                                                    icon: const Icon(Icons.edit,
                                                        size: 14),
                                                    label: Text(
                                                      currentWeekTest != null
                                                          ? 'Ändern'
                                                          : 'Zuweisen',
                                                    ),
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.deepOrange,
                                                      foregroundColor: Colors.white,
                                                    ),
                                                    onPressed: () =>
                                                        _showAssignTestDialog(
                                                      allTests,
                                                      plan.trainerId,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            if (currentWeekTest != null) ...[
                                              Text(
                                                currentWeekTest.title,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                currentWeekTest.description,
                                                style: TextStyle(
                                                    color: Colors.grey.shade800),
                                              ),
                                              const SizedBox(height: 12),
                                              if (!widget.isTrainer)
                                                ElevatedButton.icon(
                                                  icon: const Icon(Icons.play_arrow),
                                                  label: const Text(
                                                      'Leistungstest starten'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.green,
                                                    foregroundColor: Colors.white,
                                                    minimumSize: const Size(
                                                        double.infinity, 40),
                                                  ),
                                                  onPressed: () {
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            TakeTestScreen(
                                                          test: currentWeekTest,
                                                          playerId: widget
                                                              .targetPlayerId,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                            ] else ...[
                                              const Text(
                                                'Für diese Kalenderwoche wurde noch kein Leistungstest zugewiesen.',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),

                                    // TAGES-ÜBUNGEN DER WOCHE
                                    ..._daysOfWeek.map((dayName) {
                                      final daySchedule = plan.days.firstWhere(
                                        (d) => d.dayOfWeek == dayName,
                                        orElse: () => DailySchedule(
                                            dayOfWeek: dayName, scheduledExercises: []),
                                      );

                                      return Card(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 6),
                                        elevation: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    dayName,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.deepOrange,
                                                    ),
                                                  ),
                                                  if (widget.isTrainer)
                                                    IconButton(
                                                      icon: const Icon(Icons.edit,
                                                          color: Colors.deepOrange),
                                                      onPressed: () =>
                                                          _editDaySchedule(
                                                        plan,
                                                        dayName,
                                                        exercises,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const Divider(),
                                              if (daySchedule.scheduledExercises.isEmpty)
                                                const Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 8.0),
                                                  child: Text(
                                                    'Keine Übungen eingeplant',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                                  ),
                                                )
                                              else
                                                ...daySchedule.scheduledExercises.map((scheduledEx) {
                                                  final ex = exercises.firstWhere(
                                                    (e) => e.id == scheduledEx.exerciseId,
                                                    orElse: () => Exercise(
                                                      id: scheduledEx.exerciseId,
                                                      title: 'Unbekannte Übung',
                                                      description: '',
                                                      metricType: MetricType.score,
                                                    ),
                                                  );

                                                  final existingResults =
                                                      allResults
                                                          .where((r) =>
                                                              r.exerciseId == ex.id)
                                                          .toList();

                                                  final ExerciseResult?
                                                      existingResult =
                                                      existingResults.isNotEmpty
                                                          ? existingResults.first
                                                          : null;

                                                  final bool isDone =
                                                      existingResult != null;

                                                  String resultText = '';
                                                  if (isDone) {
                                                    if (ex.metricType ==
                                                        MetricType.score) {
                                                      resultText =
                                                          '${existingResult.score} Punkte';
                                                    } else if (ex.metricType ==
                                                        MetricType.hitsAndAttempts) {
                                                      resultText =
                                                          '${existingResult.hits}/${existingResult.attempts} Treffer';
                                                    } else if (ex.metricType ==
                                                        MetricType.timeInSeconds) {
                                                      resultText =
                                                          '${existingResult.timeInSeconds} Sek.';
                                                    }
                                                  }

                                                  String targetText = '';
                                                  if (scheduledEx.targetType == TargetType.duration &&
                                                      scheduledEx.targetValue.isNotEmpty) {
                                                    targetText = '⏱️ ${scheduledEx.targetValue}';
                                                  } else if (scheduledEx.targetType == TargetType.reps &&
                                                      scheduledEx.targetValue.isNotEmpty) {
                                                    targetText = '🔁 ${scheduledEx.targetValue}';
                                                  }

                                                  return ListTile(
                                                    contentPadding: EdgeInsets.zero,
                                                    leading: Icon(
                                                      isDone
                                                          ? Icons.check_circle
                                                          : Icons.fitness_center,
                                                      color: isDone
                                                          ? Colors.green
                                                          : Colors.deepOrange,
                                                    ),
                                                    title: Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            ex.title,
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.w600,
                                                              decoration: isDone
                                                                  ? TextDecoration.lineThrough
                                                                  : null,
                                                            ),
                                                          ),
                                                        ),
                                                        if (targetText.isNotEmpty)
                                                          Padding(
                                                            padding: const EdgeInsets.only(left: 6.0),
                                                            child: Chip(
                                                              label: Text(targetText,
                                                                  style: const TextStyle(
                                                                      fontSize: 10,
                                                                      color: Colors.deepOrange)),
                                                              backgroundColor: Colors.deepOrange.shade50,
                                                              visualDensity: VisualDensity.compact,
                                                              padding: EdgeInsets.zero,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    subtitle: Text(
                                                      isDone
                                                          ? 'Ergebnis: $resultText'
                                                          : ex.description,
                                                      style: TextStyle(
                                                        color: isDone
                                                            ? Colors.green.shade700
                                                            : Colors.grey.shade700,
                                                        fontWeight: isDone
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                      ),
                                                    ),
                                                    trailing: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        IconButton(
                                                          icon: const Icon(
                                                              Icons.show_chart,
                                                              color: Colors.blue),
                                                          onPressed: () {
                                                            Navigator.of(context)
                                                                .push(
                                                              MaterialPageRoute(
                                                                builder: (_) =>
                                                                    ExerciseHistoryScreen(
                                                                  exercise: ex,
                                                                  playerId: widget
                                                                      .targetPlayerId,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                        if (isDone)
                                                          ElevatedButton.icon(
                                                            onPressed: () =>
                                                                _showEnterOrEditResultDialog(
                                                              ex,
                                                              existingResult:
                                                                  existingResult,
                                                            ),
                                                            icon: const Icon(
                                                                Icons.edit,
                                                                size: 16),
                                                            label: const Text(
                                                                'Korrigieren'),
                                                            style: ElevatedButton
                                                                .styleFrom(
                                                              backgroundColor:
                                                                  Colors.orange,
                                                              foregroundColor:
                                                                  Colors.white,
                                                            ),
                                                          )
                                                        else
                                                          ElevatedButton.icon(
                                                            onPressed: () =>
                                                                _showEnterOrEditResultDialog(
                                                              ex,
                                                            ),
                                                            icon: const Icon(
                                                                Icons.check,
                                                                size: 16),
                                                            label: const Text(
                                                                'Eintragen'),
                                                            style: ElevatedButton
                                                                .styleFrom(
                                                              backgroundColor:
                                                                  Colors.green,
                                                              foregroundColor:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  );
                                                }),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}