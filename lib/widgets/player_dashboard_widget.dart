import 'package:flutter/material.dart';
import '../utils/date_utils.dart';
import '../models/user_model.dart';
import '../models/exercise_model.dart';
import '../models/result_model.dart';
import '../models/weekly_plan_model.dart';
import '../models/performance_test_model.dart';
import '../services/exercise_service.dart';
import '../services/plan_service.dart';
import '../services/result_service.dart';
import '../services/test_service.dart';
import '../screens/exercise_history_screen.dart';
import '../screens/take_test_screen.dart';

// Importieren der neu ausgegliederten Komponenten
import 'player_dashboard/dashboard_exercise_item.dart';
import 'player_dashboard/player_result_dialog.dart';
import 'player_dashboard/dashboard_header.dart';

/// Interaktives Wochen-Dashboard für Spieler mit Zielen, Avataren & Statistik-Link
class PlayerDashboardWidget extends StatefulWidget {
  final AppUser user;

  const PlayerDashboardWidget({super.key, required this.user});

  @override
  State<PlayerDashboardWidget> createState() => _PlayerDashboardWidgetState();
}

class _PlayerDashboardWidgetState extends State<PlayerDashboardWidget> {
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

  /// Öffnet den ausgelagerten Ergebniseingabe-Dialog
  void _showEnterOrEditResultDialog(DashboardExerciseItem item) {
    showDialog(
      context: context,
      builder: (context) => PlayerResultDialog(
        exercise: item.exercise,
        userId: widget.user.uid,
        dayName: item.dayName,
        currentWeekNumber: _currentWeekNumber,
        currentYear: _currentYear,
        targetType: item.targetType,
        targetValue: item.targetValue,
        trainerNote: item.trainerNote,
        existingResults: item.result != null ? [item.result!] : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PROFIL-HEADER & NAVIGATION (Ausgelagertes Widget)
          DashboardHeader(
            user: widget.user,
            currentWeekNumber: _currentWeekNumber,
            currentYear: _currentYear,
            onWeekChange: _changeWeek,
          ),
          const SizedBox(height: 16),

          // KACHEL FÜR WOCHEN-LEISTUNGSTEST
          StreamBuilder<List<PerformanceTest>>(
            stream: _testService.getTestTemplates(),
            builder: (context, testTemplatesSnapshot) {
              final allTests = testTemplatesSnapshot.data ?? [];

              return StreamBuilder<AssignedTest?>(
                stream: _testService.getAssignedTestForWeek(
                  widget.user.uid,
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

                  return Card(
                    color: Colors.deepOrange.shade100,
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.assignment, color: Colors.deepOrange),
                              SizedBox(width: 8),
                              Text(
                                'Wochen-Leistungstest',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange,
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
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentWeekTest.description,
                              style: const TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Enthaltene Übungen: ${currentWeekTest.exerciseIds.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Leistungstest jetzt starten'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 42),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TakeTestScreen(
                                      test: currentWeekTest,
                                      playerId: widget.user.uid,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ] else ...[
                            const Text(
                              'Für diese Kalenderwoche wurde dir noch kein Leistungstest zugewiesen.',
                              style: TextStyle(
                                color: Colors.black54,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // ÜBUNGEN & GESPIELTE ERGEBNISSE
          StreamBuilder<List<Exercise>>(
            stream: _exerciseService.getExercises(),
            builder: (context, exerciseSnapshot) {
              final exercises = exerciseSnapshot.data ?? [];

              return StreamBuilder<List<ExerciseResult>>(
                stream: _resultService.getResultsForPlayer(widget.user.uid),
                builder: (context, resultSnapshot) {
                  final allResults = resultSnapshot.data ?? [];

                  return StreamBuilder<TrainingPlan?>(
                    stream: _planService.getPlanForPlayerAndWeek(
                      widget.user.uid,
                      _currentYear,
                      _currentWeekNumber,
                    ),
                    builder: (context, planSnapshot) {
                      if (planSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final plan = planSnapshot.data;

                      List<DashboardExerciseItem> openItems = [];
                      List<DashboardExerciseItem> doneItems = [];

                      if (plan != null) {
                        for (int i = 0; i < _daysOfWeek.length; i++) {
                          final dayName = _daysOfWeek[i];
                          final dayDate = _getDateForDayIndex(i);

                          final daySchedule = plan.days.firstWhere(
                            (d) => d.dayOfWeek == dayName,
                            orElse: () => DailySchedule(
                              dayOfWeek: dayName,
                              scheduledExercises: [],
                            ),
                          );

                          for (var scheduledEx
                              in daySchedule.scheduledExercises) {
                            final exercise = exercises.firstWhere(
                              (e) => e.id == scheduledEx.exerciseId,
                              orElse: () => Exercise(
                                id: scheduledEx.exerciseId,
                                title: 'Unbekannte Übung',
                                description: '',
                                metricType: MetricType.score,
                              ),
                            );

                            String targetInfo = '';
                            if (scheduledEx.targetType == TargetType.duration &&
                                scheduledEx.targetValue.isNotEmpty) {
                              targetInfo =
                                  '⏱️ Vorgabe: ${scheduledEx.targetValue}';
                            } else if (scheduledEx.targetType ==
                                    TargetType.reps &&
                                scheduledEx.targetValue.isNotEmpty) {
                              targetInfo =
                                  '🔁 Vorgabe: ${scheduledEx.targetValue}';
                            }

                            final existingResult = allResults.where((r) {
                              return r.exerciseId == scheduledEx.exerciseId &&
                                  r.dayOfWeek == dayName &&
                                  r.weekNumber == _currentWeekNumber &&
                                  r.year == _currentYear;
                            }).firstOrNull;

                            final isOverdue =
                                existingResult == null &&
                                dayDate.isBefore(todayMidnight);

                            final item = DashboardExerciseItem(
                              exercise: exercise,
                              dayName: dayName,
                              scheduledDate: dayDate,
                              result: existingResult,
                              isOverdue: isOverdue,
                              targetInfo: targetInfo,
                              targetType: scheduledEx.targetType,
                              targetValue: scheduledEx.targetValue,
                              trainerNote: scheduledEx.note,
                            );

                            if (existingResult != null) {
                              doneItems.add(item);
                            } else {
                              openItems.add(item);
                            }
                          }
                        }
                      }

                      return DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            TabBar(
                              indicatorColor: Colors.deepOrange,
                              labelColor: Colors.deepOrange,
                              unselectedLabelColor: Colors.grey,
                              tabs: [
                                Tab(
                                  text: 'Offen (${openItems.length})',
                                  icon: const Icon(Icons.fitness_center),
                                ),
                                Tab(
                                  text: 'Gespielt (${doneItems.length})',
                                  icon: const Icon(Icons.check_circle_outline),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            SizedBox(
                              height: 380,
                              child: TabBarView(
                                children: [
                                  // TAB 1: OFFENE ÜBUNGEN
                                  openItems.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'Keine offenen Tages-Übungen in dieser Woche! 🎉',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          itemCount: openItems.length,
                                          itemBuilder: (context, index) {
                                            final item = openItems[index];

                                            return Card(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 6,
                                                  ),
                                              color: item.isOverdue
                                                  ? Colors.red.shade900
                                                        .withOpacity(0.15)
                                                  : null,
                                              shape: RoundedRectangleBorder(
                                                side: BorderSide(
                                                  color: item.isOverdue
                                                      ? Colors.red
                                                      : Colors.transparent,
                                                  width: 1.5,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: ListTile(
                                                leading: CircleAvatar(
                                                  backgroundColor:
                                                      item.isOverdue
                                                      ? Colors.red
                                                      : Colors.deepOrange,
                                                  child: Icon(
                                                    item.isOverdue
                                                        ? Icons
                                                              .warning_amber_rounded
                                                        : Icons.schedule,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                title: Text(
                                                  item.exercise.title,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                subtitle: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '${item.dayName} (${item.scheduledDate.day}.${item.scheduledDate.month}.)' +
                                                          (item.isOverdue
                                                              ? ' • VERPASST / ÜBERFÄLLIG'
                                                              : ''),
                                                      style: TextStyle(
                                                        color: item.isOverdue
                                                            ? Colors.red
                                                            : Colors
                                                                  .grey
                                                                  .shade700,
                                                        fontWeight:
                                                            item.isOverdue
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                      ),
                                                    ),
                                                    if (item
                                                        .targetInfo
                                                        .isNotEmpty) ...[
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        item.targetInfo,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Colors.deepOrange,
                                                        ),
                                                      ),
                                                    ],
                                                    if (item.trainerNote !=
                                                            null &&
                                                        item
                                                            .trainerNote!
                                                            .isNotEmpty) ...[
                                                      const SizedBox(height: 2),
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                            Icons
                                                                .sports_rounded,
                                                            size: 13,
                                                            color: Colors.amber,
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              'Trainer: "${item.trainerNote}"',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                fontStyle:
                                                                    FontStyle
                                                                        .italic,
                                                                color: Colors
                                                                    .amber
                                                                    .shade900,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                    if (item
                                                        .exercise
                                                        .description
                                                        .isNotEmpty) ...[
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        item
                                                            .exercise
                                                            .description,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                trailing: ElevatedButton(
                                                  onPressed: () =>
                                                      _showEnterOrEditResultDialog(
                                                        item,
                                                      ),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            item.isOverdue
                                                            ? Colors.red
                                                            : Colors.green,
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                  child: const Text(
                                                    'Eintragen',
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),

                                  // TAB 2: BEREITS GESPIELTE ÜBUNGEN
                                  doneItems.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'Noch keine Übungen in dieser Woche absolviert.',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          itemCount: doneItems.length,
                                          itemBuilder: (context, index) {
                                            final item = doneItems[index];

                                            String resultVal = '';
                                            if (item.result != null) {
                                              if (item.exercise.metricType ==
                                                  MetricType.score) {
                                                resultVal =
                                                    '${item.result!.score} Punkte';
                                              } else if (item
                                                      .exercise
                                                      .metricType ==
                                                  MetricType.hits) {
                                                resultVal =
                                                    '${item.result!.hits} Treffer';
                                              } else if (item
                                                      .exercise
                                                      .metricType ==
                                                  MetricType.attempts) {
                                                resultVal =
                                                    '${item.result!.attempts} Versuche';
                                              } else if (item
                                                      .exercise
                                                      .metricType ==
                                                  MetricType.timeInSeconds) {
                                                resultVal =
                                                    '${item.result!.timeInSeconds} Sek.';
                                              }
                                            }

                                            // --- DATUMS-VERGLEICH ---
                                            final DateTime? playedAt =
                                                item.result?.timestamp;
                                            final String playedAtFormatted =
                                                playedAt != null
                                                ? DateUtilsHelper.formatTimestamp(
                                                    playedAt,
                                                  )
                                                : 'Unbekannt';

                                            // Prüfen, ob das Spieldatum vom geplanten Kalendertag abweicht
                                            bool isDifferentDay = false;
                                            if (playedAt != null) {
                                              final playedDateMidnight =
                                                  DateTime(
                                                    playedAt.year,
                                                    playedAt.month,
                                                    playedAt.day,
                                                  );
                                              final scheduledDateMidnight =
                                                  DateTime(
                                                    item.scheduledDate.year,
                                                    item.scheduledDate.month,
                                                    item.scheduledDate.day,
                                                  );
                                              isDifferentDay =
                                                  !playedDateMidnight
                                                      .isAtSameMomentAs(
                                                        scheduledDateMidnight,
                                                      );
                                            }

                                            return Card(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 6,
                                                  ),
                                              child: ListTile(
                                                leading: const CircleAvatar(
                                                  backgroundColor: Colors.green,
                                                  child: Icon(
                                                    Icons.check,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                title: Text(
                                                  item.exercise.title,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                subtitle: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const SizedBox(height: 2),
                                                    // Ergebnis-Anzeige
                                                    Text(
                                                      'Ergebnis: $resultVal',
                                                      style: const TextStyle(
                                                        color: Colors.green,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),

                                                    // Geplanter Tag im Wochenplan
                                                    Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.calendar_today,
                                                          size: 12,
                                                          color: Colors.grey,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          'Im Plan für: ${item.dayName} (${item.scheduledDate.day}.${item.scheduledDate.month}.)',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors
                                                                .grey
                                                                .shade800,
                                                          ),
                                                        ),
                                                      ],
                                                    ),

                                                    // Tatsächliches Eingabedatum (Timestamp)
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .access_time_rounded,
                                                          size: 12,
                                                          color: isDifferentDay
                                                              ? Colors
                                                                    .deepOrange
                                                              : Colors.grey,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            'Eingetragen: $playedAtFormatted' +
                                                                (isDifferentDay
                                                                    ? ' (Abweichender Tag)'
                                                                    : ''),
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  isDifferentDay
                                                                  ? FontWeight
                                                                        .w600
                                                                  : FontWeight
                                                                        .normal,
                                                              color:
                                                                  isDifferentDay
                                                                  ? Colors
                                                                        .deepOrange
                                                                        .shade800
                                                                  : Colors
                                                                        .grey
                                                                        .shade700,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),

                                                    // Vorgabe-Informationen (falls vorhanden)
                                                    if (item
                                                        .targetInfo
                                                        .isNotEmpty) ...[
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        item.targetInfo,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 12,
                                                          color:
                                                              Colors.deepOrange,
                                                        ),
                                                      ),
                                                    ],

                                                    // Trainer-Hinweis (falls vorhanden)
                                                    if (item.trainerNote !=
                                                            null &&
                                                        item
                                                            .trainerNote!
                                                            .isNotEmpty) ...[
                                                      const SizedBox(height: 2),
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                            Icons
                                                                .sports_rounded,
                                                            size: 13,
                                                            color: Colors.amber,
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              'Trainer: "${item.trainerNote}"',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                fontStyle:
                                                                    FontStyle
                                                                        .italic,
                                                                color: Colors
                                                                    .amber
                                                                    .shade900,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                trailing: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.show_chart,
                                                        color: Colors.blue,
                                                      ),
                                                      tooltip:
                                                          'Historie anzeigen',
                                                      onPressed: () {
                                                        Navigator.of(
                                                          context,
                                                        ).push(
                                                          MaterialPageRoute(
                                                            builder: (_) =>
                                                                ExerciseHistoryScreen(
                                                                  exercise: item
                                                                      .exercise,
                                                                  playerId:
                                                                      widget
                                                                          .user
                                                                          .uid,
                                                                ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                    ElevatedButton.icon(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        size: 14,
                                                      ),
                                                      label: const Text(
                                                        'Korrigieren',
                                                      ),
                                                      style:
                                                          ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                Colors.orange,
                                                            foregroundColor:
                                                                Colors.white,
                                                          ),
                                                      onPressed: () =>
                                                          _showEnterOrEditResultDialog(
                                                            item,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
