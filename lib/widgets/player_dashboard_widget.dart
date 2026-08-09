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

/// Interaktives Wochen-Dashboard für Spieler mit Zielen, Avataren & Statistik-Link.
/// Speziell für Smartphones und schmale Displays optimiert.
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
                            if (currentWeekTest.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                currentWeekTest.description,
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
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
                                minimumSize: const Size(double.infinity, 44),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
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
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.deepOrange),
                        );
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
                              height: 440, // Leicht erhöht für Mobil-Karten
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
                                              margin: const EdgeInsets.symmetric(
                                                vertical: 6,
                                              ),
                                              color: item.isOverdue
                                                  ? Colors.red.shade900
                                                      .withOpacity(0.12)
                                                  : null,
                                              shape: RoundedRectangleBorder(
                                                side: BorderSide(
                                                  color: item.isOverdue
                                                      ? Colors.red
                                                      : Colors.grey.shade300,
                                                  width: item.isOverdue ? 1.5 : 1,
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
                                                    // HEADER DER ÜBUNG (Icon, Titel, Datum)
                                                    Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment.start,
                                                      children: [
                                                        CircleAvatar(
                                                          radius: 18,
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
                                                            size: 20,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                item.exercise.title,
                                                                style: const TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight.bold,
                                                                ),
                                                                overflow:
                                                                    TextOverflow.ellipsis,
                                                              ),
                                                              const SizedBox(height: 2),
                                                              Text(
                                                                '${item.dayName} (${item.scheduledDate.day}.${item.scheduledDate.month}.)' +
                                                                    (item.isOverdue
                                                                        ? ' • VERPASST / ÜBERFÄLLIG'
                                                                        : ''),
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: item.isOverdue
                                                                      ? Colors.red
                                                                      : Colors.grey
                                                                          .shade700,
                                                                  fontWeight:
                                                                      item.isOverdue
                                                                          ? FontWeight.bold
                                                                          : FontWeight.normal,
                                                                ),
                                                                overflow:
                                                                    TextOverflow.ellipsis,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),

                                                    // INHALT & HINWEISE
                                                    if (item.targetInfo.isNotEmpty) ...[
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        item.targetInfo,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 13,
                                                          color: Colors.deepOrange,
                                                        ),
                                                      ),
                                                    ],

                                                    if (item.trainerNote != null &&
                                                        item.trainerNote!.isNotEmpty) ...[
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                            Icons.sports_rounded,
                                                            size: 14,
                                                            color: Colors.amber,
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Expanded(
                                                            child: Text(
                                                              'Trainer: "${item.trainerNote}"',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                fontStyle: FontStyle.italic,
                                                                color: Colors.amber.shade900,
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],

                                                    const SizedBox(height: 10),

                                                    // AKTION: BUTTON FÜR EINTRAGEN (Volle Breite)
                                                    SizedBox(
                                                      width: double.infinity,
                                                      child: ElevatedButton.icon(
                                                        icon: const Icon(Icons.add_task, size: 18),
                                                        label: const Text('Ergebnis eintragen'),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: item.isOverdue
                                                              ? Colors.red
                                                              : Colors.green,
                                                          foregroundColor: Colors.white,
                                                          visualDensity: VisualDensity.compact,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                        ),
                                                        onPressed: () =>
                                                            _showEnterOrEditResultDialog(item),
                                                      ),
                                                    ),
                                                  ],
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
                                              if (item.exercise.metricType == MetricType.score) {
                                                resultVal = '${item.result!.score} Punkte';
                                              } else if (item.exercise.metricType == MetricType.hits) {
                                                resultVal = '${item.result!.hits} Treffer';
                                              } else if (item.exercise.metricType == MetricType.attempts) {
                                                resultVal = '${item.result!.attempts} Versuche';
                                              } else if (item.exercise.metricType == MetricType.timeInSeconds) {
                                                resultVal = '${item.result!.timeInSeconds} Sek.';
                                              }
                                            }

                                            final DateTime? playedAt = item.result?.timestamp;
                                            final String playedAtFormatted = playedAt != null
                                                ? DateUtilsHelper.formatTimestamp(playedAt)
                                                : 'Unbekannt';

                                            bool isDifferentDay = false;
                                            if (playedAt != null) {
                                              final playedDateMidnight = DateTime(
                                                playedAt.year,
                                                playedAt.month,
                                                playedAt.day,
                                              );
                                              final scheduledDateMidnight = DateTime(
                                                item.scheduledDate.year,
                                                item.scheduledDate.month,
                                                item.scheduledDate.day,
                                              );
                                              isDifferentDay = !playedDateMidnight
                                                  .isAtSameMomentAs(scheduledDateMidnight);
                                            }

                                            return Card(
                                              margin: const EdgeInsets.symmetric(
                                                vertical: 6,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(12.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    // HEADER (Grüner Haken, Titel, Ergebnis)
                                                    Row(
                                                      children: [
                                                        const CircleAvatar(
                                                          radius: 16,
                                                          backgroundColor: Colors.green,
                                                          child: Icon(
                                                            Icons.check,
                                                            color: Colors.white,
                                                            size: 18,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 10),
                                                        Expanded(
                                                          child: Text(
                                                            item.exercise.title,
                                                            style: const TextStyle(
                                                              fontSize: 16,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        Text(
                                                          resultVal,
                                                          style: const TextStyle(
                                                            color: Colors.green,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 15,
                                                          ),
                                                        ),
                                                      ],
                                                    ),

                                                    const SizedBox(height: 6),

                                                    // DETAILS (Geplant vs. Eingetragen)
                                                    Text(
                                                      'Geplant: ${item.dayName} (${item.scheduledDate.day}.${item.scheduledDate.month}.)',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey.shade700,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Eingetragen: $playedAtFormatted' +
                                                          (isDifferentDay ? ' (Abweichend)' : ''),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: isDifferentDay
                                                            ? Colors.deepOrange.shade800
                                                            : Colors.grey.shade700,
                                                        fontWeight: isDifferentDay
                                                            ? FontWeight.w600
                                                            : FontWeight.normal,
                                                      ),
                                                    ),

                                                    const Divider(height: 16),

                                                    // BUTTON-LEISTE FÜR MOBIL (Historie & Korrigieren)
                                                    Row(
                                                      children: [
                                                        // Button 1: Historie
                                                        Expanded(
                                                          child: OutlinedButton.icon(
                                                            icon: const Icon(
                                                              Icons.show_chart,
                                                              size: 16,
                                                              color: Colors.blue,
                                                            ),
                                                            label: const Text(
                                                              'Historie',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors.blue,
                                                              ),
                                                            ),
                                                            style: OutlinedButton.styleFrom(
                                                              side: const BorderSide(color: Colors.blue),
                                                              padding: const EdgeInsets.symmetric(vertical: 6),
                                                              visualDensity: VisualDensity.compact,
                                                            ),
                                                            onPressed: () {
                                                              Navigator.of(context).push(
                                                                MaterialPageRoute(
                                                                  builder: (_) => ExerciseHistoryScreen(
                                                                    exercise: item.exercise,
                                                                    playerId: widget.user.uid,
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),

                                                        // Button 2: Korrigieren
                                                        Expanded(
                                                          child: ElevatedButton.icon(
                                                            icon: const Icon(
                                                              Icons.edit,
                                                              size: 16,
                                                            ),
                                                            label: const Text(
                                                              'Korrigieren',
                                                              style: TextStyle(fontSize: 12),
                                                            ),
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: Colors.orange,
                                                              foregroundColor: Colors.white,
                                                              padding: const EdgeInsets.symmetric(vertical: 6),
                                                              visualDensity: VisualDensity.compact,
                                                            ),
                                                            onPressed: () =>
                                                                _showEnterOrEditResultDialog(item),
                                                          ),
                                                        ),
                                                      ],
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