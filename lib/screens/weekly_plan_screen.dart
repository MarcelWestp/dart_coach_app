import 'package:flutter/material.dart';
import '../models/exercise_model.dart';
import '../models/result_model.dart';
import '../models/weekly_plan_model.dart';
import '../models/performance_test_model.dart';
import '../services/exercise_service.dart';
import '../services/plan_service.dart';
import '../services/result_service.dart';
import '../services/test_service.dart';
import 'exercise_history_screen.dart';
import 'take_test_screen.dart';
import '../widgets/weekly_plan/edit_trainer_note_dialog.dart';
import '../widgets/weekly_plan/assign_test_dialog.dart';
import '../widgets/weekly_plan/edit_day_schedule_dialog.dart';
import '../widgets/weekly_plan/enter_or_edit_result_dialog.dart';

/// Wochenansicht mit integrierter Leistungstest-Zuweisung, Tag-Filtern, Vorgaben und Trainer-Notizen.
/// Enthält optische Hervorhebung des heutigen Tages und Schnell-Navigation zur aktuellen Woche.
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
    'Sonntag',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _updateWeekAndYear();
  }

  void _updateWeekAndYear() {
    int w =
        ((_selectedDate.difference(DateTime(_selectedDate.year, 1, 1)).inDays +
                    1) /
                7)
            .ceil();
    _currentWeekNumber = w > 52 ? 52 : (w == 0 ? 1 : w);
    _currentYear = _selectedDate.year;
  }

  void _changeWeek(int weeksToAdd) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: weeksToAdd * 7));
      _updateWeekAndYear();
    });
  }

  /// Springt sofort zur aktuellen Kalenderwoche zurück
  void _jumpToCurrentWeek() {
    setState(() {
      _selectedDate = DateTime.now();
      _updateWeekAndYear();
    });
  }

  /// Berechnet das exakte Datum für einen bestimmten Wochentag (0 = Montag, 6 = Sonntag)
  DateTime _getDateForDayIndex(int dayIndex) {
    DateTime monday = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );
    return DateTime(
      monday.year,
      monday.month,
      monday.day,
    ).add(Duration(days: dayIndex));
  }

  /// Dialog für Trainer zur Zuweisung eines Leistungstests für die aktuelle KW
  void _showAssignTestDialog(
    List<PerformanceTest> availableTests,
    String currentTrainerId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AssignTestDialog(
        availableTests: availableTests,
        targetPlayerId: widget.targetPlayerId,
        currentTrainerId: currentTrainerId,
        year: _currentYear,
        weekNumber: _currentWeekNumber,
      ),
    );
  }

  /// Dialog für Trainer zum Hinzufügen / Bearbeiten einer Notiz zu einer geplanten Übung
  void _showEditTrainerNoteDialog(
    TrainingPlan currentPlan,
    String dayName,
    ScheduledExercise scheduledEx,
    String exerciseTitle,
  ) {
    showDialog(
      context: context,
      builder: (context) => EditTrainerNoteDialog(
        currentPlan: currentPlan,
        dayName: dayName,
        scheduledEx: scheduledEx,
        exerciseTitle: exerciseTitle,
      ),
    );
  }

  /// Dialog zum Eintragen oder Korrigieren eines Ergebnisses
  void _showEnterOrEditResultDialog(
    Exercise exercise, {
    ExerciseResult? existingResult,
  }) {
    showDialog(
      context: context,
      builder: (context) => EnterOrEditResultDialog(
        exercise: exercise,
        targetPlayerId: widget.targetPlayerId,
        existingResult: existingResult,
      ),
    );
  }

  /// Bearbeiten der Tagesübungen inklusive Tag-Filter und Vorgaben
  void _editDaySchedule(
    TrainingPlan currentPlan,
    String dayName,
    List<Exercise> availableExercises,
  ) {
    showDialog(
      context: context,
      builder: (context) => EditDayScheduleDialog(
        currentPlan: currentPlan,
        dayName: dayName,
        availableExercises: availableExercises,
        weekNumber: _currentWeekNumber,
        targetPlayerId: widget.targetPlayerId,
        daysOfWeek: _daysOfWeek,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    return Scaffold(
      appBar: AppBar(title: const Text('Wochen-Trainingsplan')),
      body: Column(
        children: [
          // WOCHEN-NAVIGATION MIT HEUTE-BUTTON
          Container(
            color: Colors.deepOrange.shade50,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  tooltip: 'Vorherige Woche',
                  onPressed: () => _changeWeek(-1),
                ),
                Row(
                  children: [
                    Text(
                      'Kalenderwoche $_currentWeekNumber ($_currentYear)',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(
                        Icons.today,
                        color: Colors.deepOrange,
                      ),
                      tooltip: 'Zur aktuellen Woche springen',
                      onPressed: _jumpToCurrentWeek,
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  tooltip: 'Nächste Woche',
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
                    final PerformanceTest? currentWeekTest =
                        assignedTest != null
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
                          stream: _resultService.getResultsForPlayer(
                            widget.targetPlayerId,
                          ),
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
                                    child: CircularProgressIndicator(
                                      color: Colors.deepOrange,
                                    ),
                                  );
                                }

                                final plan =
                                    planSnapshot.data ??
                                    TrainingPlan(
                                      id: '',
                                      title: 'Wochenplan',
                                      playerId: widget.targetPlayerId,
                                      trainerId: '',
                                      year: _currentYear,
                                      weekNumber: _currentWeekNumber,
                                      days: _daysOfWeek
                                          .map(
                                            (d) => DailySchedule(
                                              dayOfWeek: d,
                                              scheduledExercises: [],
                                            ),
                                          )
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
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Row(
                                                  children: [
                                                    Icon(
                                                      Icons.assignment,
                                                      color: Colors.deepOrange,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Wochen-Leistungstest',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors.deepOrange,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (widget.isTrainer)
                                                  ElevatedButton.icon(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      size: 14,
                                                    ),
                                                    label: Text(
                                                      currentWeekTest != null
                                                          ? 'Ändern'
                                                          : 'Zuweisen',
                                                    ),
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.deepOrange,
                                                      foregroundColor:
                                                          Colors.white,
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
                                                  color: Colors.grey.shade800,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              if (!widget.isTrainer)
                                                ElevatedButton.icon(
                                                  icon: const Icon(
                                                    Icons.play_arrow,
                                                  ),
                                                  label: const Text(
                                                    'Leistungstest starten',
                                                  ),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.green,
                                                    foregroundColor:
                                                        Colors.white,
                                                    minimumSize: const Size(
                                                      double.infinity,
                                                      40,
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            TakeTestScreen(
                                                          test:
                                                              currentWeekTest,
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
                                    ...List.generate(_daysOfWeek.length, (index) {
                                      final dayName = _daysOfWeek[index];
                                      final dayDate = _getDateForDayIndex(index);
                                      final bool isToday = dayDate.isAtSameMomentAs(todayMidnight);

                                      final daySchedule = plan.days.firstWhere(
                                        (d) => d.dayOfWeek == dayName,
                                        orElse: () => DailySchedule(
                                          dayOfWeek: dayName,
                                          scheduledExercises: [],
                                        ),
                                      );

                                      return Card(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 6,
                                        ),
                                        elevation: isToday ? 4 : 2,
                                        color: isToday
                                            ? Colors.deepOrange.shade50
                                            : null,
                                        shape: RoundedRectangleBorder(
                                          side: isToday
                                              ? const BorderSide(
                                                  color: Colors.deepOrange,
                                                  width: 2,
                                                )
                                              : BorderSide(
                                                  color: Colors.grey.shade300,
                                                ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
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
                                                  Row(
                                                    children: [
                                                      Text(
                                                        dayName,
                                                        style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: isToday
                                                              ? Colors.deepOrange.shade900
                                                              : Colors.deepOrange,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        '(${dayDate.day}.${dayDate.month}.)',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: isToday
                                                              ? Colors.deepOrange.shade800
                                                              : Colors.grey.shade600,
                                                          fontWeight: isToday
                                                              ? FontWeight.bold
                                                              : FontWeight.normal,
                                                        ),
                                                      ),
                                                      if (isToday) ...[
                                                        const SizedBox(width: 8),
                                                        Chip(
                                                          label: const Text(
                                                            'HEUTE',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontWeight:
                                                                  FontWeight.bold,
                                                              fontSize: 10,
                                                            ),
                                                          ),
                                                          backgroundColor:
                                                              Colors.deepOrange,
                                                          visualDensity:
                                                              VisualDensity.compact,
                                                          padding:
                                                              EdgeInsets.zero,
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  if (widget.isTrainer)
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        color:
                                                            Colors.deepOrange,
                                                      ),
                                                      tooltip:
                                                          'Übungen für $dayName auswählen',
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
                                              if (daySchedule
                                                  .scheduledExercises
                                                  .isEmpty)
                                                const Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    vertical: 8.0,
                                                  ),
                                                  child: Text(
                                                    'Keine Übungen eingeplant',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                    ),
                                                  ),
                                                )
                                              else
                                                ...daySchedule.scheduledExercises.map((
                                                  scheduledEx,
                                                ) {
                                                  final ex = exercises
                                                      .firstWhere(
                                                        (e) =>
                                                            e.id ==
                                                            scheduledEx
                                                                .exerciseId,
                                                        orElse: () => Exercise(
                                                          id: scheduledEx
                                                              .exerciseId,
                                                          title:
                                                              'Unbekannte Übung',
                                                          description: '',
                                                          metricType:
                                                              MetricType.score,
                                                        ),
                                                      );

                                                  final existingResults =
                                                      allResults.where((r) {
                                                    return r.exerciseId ==
                                                            ex.id &&
                                                        r.dayOfWeek ==
                                                            dayName &&
                                                        r.weekNumber ==
                                                            _currentWeekNumber &&
                                                        r.year ==
                                                            _currentYear;
                                                  }).toList();

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
                                                        MetricType.hits) {
                                                      resultText =
                                                          '${existingResult.hits} Treffer';
                                                    } else if (ex.metricType ==
                                                        MetricType.attempts) {
                                                      resultText =
                                                          '${existingResult.attempts} Versuche';
                                                    } else if (ex.metricType ==
                                                        MetricType
                                                            .timeInSeconds) {
                                                      resultText =
                                                          '${existingResult.timeInSeconds} Sek.';
                                                    }
                                                  }

                                                  String targetText = '';
                                                  if (scheduledEx.targetType ==
                                                          TargetType.duration &&
                                                      scheduledEx
                                                          .targetValue
                                                          .isNotEmpty) {
                                                    targetText =
                                                        '⏱️ ${scheduledEx.targetValue}';
                                                  } else if (scheduledEx
                                                              .targetType ==
                                                          TargetType.reps &&
                                                      scheduledEx
                                                          .targetValue
                                                          .isNotEmpty) {
                                                    targetText =
                                                        '🔁 ${scheduledEx.targetValue}';
                                                  }

                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      ListTile(
                                                        contentPadding:
                                                            EdgeInsets.zero,
                                                        leading: Icon(
                                                          isDone
                                                              ? Icons
                                                                  .check_circle
                                                              : Icons
                                                                  .fitness_center,
                                                          color: isDone
                                                              ? Colors.green
                                                              : Colors
                                                                  .deepOrange,
                                                        ),
                                                        title: Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                ex.title,
                                                                style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  decoration:
                                                                      isDone
                                                                          ? TextDecoration
                                                                              .lineThrough
                                                                          : null,
                                                                ),
                                                              ),
                                                            ),
                                                            if (targetText
                                                                .isNotEmpty)
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets.only(
                                                                  left: 6.0,
                                                                ),
                                                                child: Chip(
                                                                  label: Text(
                                                                    targetText,
                                                                    style: const TextStyle(
                                                                      fontSize:
                                                                          10,
                                                                      color: Colors
                                                                          .deepOrange,
                                                                    ),
                                                                  ),
                                                                  backgroundColor: Colors
                                                                      .deepOrange
                                                                      .shade50,
                                                                  visualDensity:
                                                                      VisualDensity
                                                                          .compact,
                                                                  padding:
                                                                      EdgeInsets
                                                                          .zero,
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
                                                                ? Colors
                                                                    .green
                                                                    .shade700
                                                                : Colors
                                                                    .grey
                                                                    .shade700,
                                                            fontWeight: isDone
                                                                ? FontWeight
                                                                    .bold
                                                                : FontWeight
                                                                    .normal,
                                                          ),
                                                        ),
                                                        trailing: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            if (widget
                                                                .isTrainer)
                                                              IconButton(
                                                                icon: Icon(
                                                                  scheduledEx.note !=
                                                                              null &&
                                                                          scheduledEx
                                                                              .note!
                                                                              .isNotEmpty
                                                                      ? Icons
                                                                          .edit_note
                                                                      : Icons
                                                                          .note_add_outlined,
                                                                  color: Colors
                                                                      .amber
                                                                      .shade900,
                                                                ),
                                                                tooltip:
                                                                    'Trainer-Notiz bearbeiten',
                                                                onPressed: () =>
                                                                    _showEditTrainerNoteDialog(
                                                                  plan,
                                                                  dayName,
                                                                  scheduledEx,
                                                                  ex.title,
                                                                ),
                                                              ),
                                                            IconButton(
                                                              icon: const Icon(
                                                                Icons
                                                                    .show_chart,
                                                                color:
                                                                    Colors.blue,
                                                              ),
                                                              onPressed: () {
                                                                Navigator.of(
                                                                  context,
                                                                ).push(
                                                                  MaterialPageRoute(
                                                                    builder: (_) => ExerciseHistoryScreen(
                                                                      exercise:
                                                                          ex,
                                                                      playerId:
                                                                          widget
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
                                                                icon:
                                                                    const Icon(
                                                                  Icons
                                                                      .edit,
                                                                  size: 16,
                                                                ),
                                                                label: const Text(
                                                                  'Korrigieren',
                                                                ),
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .orange,
                                                                  foregroundColor:
                                                                      Colors
                                                                          .white,
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
                                                                  size: 16,
                                                                ),
                                                                label: const Text(
                                                                  'Eintragen',
                                                                ),
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .green,
                                                                  foregroundColor:
                                                                      Colors
                                                                          .white,
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                      if (scheduledEx.note !=
                                                              null &&
                                                          scheduledEx
                                                              .note!
                                                              .isNotEmpty)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                            left: 40.0,
                                                            bottom: 8.0,
                                                          ),
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                              horizontal:
                                                                  10,
                                                              vertical: 6,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: Colors
                                                                  .amber
                                                                  .shade50,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                6,
                                                              ),
                                                              border: Border.all(
                                                                color: Colors
                                                                    .amber
                                                                    .shade300,
                                                              ),
                                                            ),
                                                            child: Row(
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .sports_rounded,
                                                                  size: 14,
                                                                  color: Colors
                                                                      .amber
                                                                      .shade900,
                                                                ),
                                                                const SizedBox(
                                                                  width: 6,
                                                                ),
                                                                Expanded(
                                                                  child: Text(
                                                                    'Trainer-Hinweis: ${scheduledEx.note}',
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      color: Colors
                                                                          .amber
                                                                          .shade900,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                    ],
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