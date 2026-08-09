import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/exercise_model.dart';
import '../models/result_model.dart';
import '../models/weekly_plan_model.dart';
import '../models/performance_test_model.dart'; // NEU: Modell-Import
import '../services/exercise_service.dart';
import '../services/plan_service.dart';
import '../services/result_service.dart';
import '../services/test_service.dart'; // NEU: Service-Import
import '../screens/exercise_history_screen.dart';
import '../screens/take_test_screen.dart'; // NEU: Erfassungs-Bildschirm
import 'user_avatar_widget.dart';

/// Interaktives Wochen-Dashboard für Spieler inklusive Leistungstest-Kachel
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
  final TestService _testService = TestService(); // NEU: TestService Instanz

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

  DateTime _getDateForDayIndex(int dayIndex) {
    DateTime monday = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day).add(Duration(days: dayIndex));
  }

  void _showEnterResultDialog(Exercise exercise) {
    final scoreController = TextEditingController();
    final hitsController = TextEditingController();
    final attemptsController = TextEditingController();
    final timeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ergebnis eintragen',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(exercise.title,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                  id: '',
                  playerId: widget.user.uid,
                  exerciseId: exercise.id,
                  timestamp: DateTime.now(),
                  score: int.tryParse(scoreController.text.trim()),
                  hits: int.tryParse(hitsController.text.trim()),
                  attempts: int.tryParse(attemptsController.text.trim()),
                  timeInSeconds: int.tryParse(timeController.text.trim()),
                );

                await _resultService.saveResult(newResult);

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ergebnis erfolgreich gespeichert!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Speichern'),
            ),
          ],
        );
      },
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
          // PROFIL-HEADER KARTEN
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  UserAvatarWidget(user: widget.user, radius: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Willkommen, ${widget.user.name}!',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.user.club != null && widget.user.club!.isNotEmpty
                              ? '${widget.user.club} ${widget.user.team != null ? "(${widget.user.team})" : ""}'
                              : 'Spieler Dashboard',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // WOCHEN-FILTER NAVIGATION
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 18),
                  onPressed: () => _changeWeek(-1),
                ),
                Text(
                  'Kalenderwoche $_currentWeekNumber ($_currentYear)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 18),
                  onPressed: () => _changeWeek(1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // NEU: KACHEL FÜR DEN ZUGEWIESENEN LEISTUNGSTEST DER WOCHE
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
                                  fontWeight: FontWeight.w600, color: Colors.black87),
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

          // DATEN LADEN: ÜBUNGEN, ERGEBNISSE & PLAN
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

                      List<_DashboardExerciseItem> openItems = [];
                      List<_DashboardExerciseItem> doneItems = [];

                      if (plan != null) {
                        for (int i = 0; i < _daysOfWeek.length; i++) {
                          final dayName = _daysOfWeek[i];
                          final dayDate = _getDateForDayIndex(i);

                          final daySchedule = plan.days.firstWhere(
                            (d) => d.dayOfWeek == dayName,
                            orElse: () =>
                                DailySchedule(dayOfWeek: dayName, exerciseIds: []),
                          );

                          for (var exId in daySchedule.exerciseIds) {
                            final exercise = exercises.firstWhere(
                              (e) => e.id == exId,
                              orElse: () => Exercise(
                                id: exId,
                                title: 'Unbekannte Übung',
                                description: '',
                                metricType: MetricType.score,
                              ),
                            );

                            final existingResult = allResults
                                .where((r) => r.exerciseId == exId)
                                .firstOrNull;

                            final isOverdue = existingResult == null &&
                                dayDate.isBefore(todayMidnight);

                            final item = _DashboardExerciseItem(
                              exercise: exercise,
                              dayName: dayName,
                              scheduledDate: dayDate,
                              result: existingResult,
                              isOverdue: isOverdue,
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
                                            style: TextStyle(color: Colors.grey),
                                          ),
                                        )
                                      : ListView.builder(
                                          itemCount: openItems.length,
                                          itemBuilder: (context, index) {
                                            final item = openItems[index];

                                            return Card(
                                              margin: const EdgeInsets.symmetric(
                                                  vertical: 6),
                                              color: item.isOverdue
                                                  ? Colors.red.shade900.withOpacity(0.15)
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
                                                  backgroundColor: item.isOverdue
                                                      ? Colors.red
                                                      : Colors.deepOrange,
                                                  child: Icon(
                                                    item.isOverdue
                                                        ? Icons.warning_amber_rounded
                                                        : Icons.schedule,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                title: Text(
                                                  item.exercise.title,
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.bold),
                                                ),
                                                subtitle: Text(
                                                  '${item.dayName} (${item.scheduledDate.day}.${item.scheduledDate.month}.)' +
                                                      (item.isOverdue
                                                          ? ' • VERPASST / ÜBERFÄLLIG'
                                                          : ''),
                                                  style: TextStyle(
                                                    color: item.isOverdue
                                                        ? Colors.red
                                                        : Colors.grey.shade700,
                                                    fontWeight: item.isOverdue
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                                trailing: ElevatedButton(
                                                  onPressed: () =>
                                                      _showEnterResultDialog(
                                                          item.exercise),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: item.isOverdue
                                                        ? Colors.red
                                                        : Colors.green,
                                                    foregroundColor: Colors.white,
                                                  ),
                                                  child: const Text('Eintragen'),
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
                                            style: TextStyle(color: Colors.grey),
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
                                              } else if (item.exercise.metricType ==
                                                  MetricType.hitsAndAttempts) {
                                                resultVal =
                                                    '${item.result!.hits}/${item.result!.attempts} Treffer';
                                              } else if (item.exercise.metricType ==
                                                  MetricType.timeInSeconds) {
                                                resultVal =
                                                    '${item.result!.timeInSeconds} Sek.';
                                              }
                                            }

                                            return Card(
                                              margin: const EdgeInsets.symmetric(
                                                  vertical: 6),
                                              child: ListTile(
                                                leading: const CircleAvatar(
                                                  backgroundColor: Colors.green,
                                                  child: Icon(Icons.check,
                                                      color: Colors.white),
                                                ),
                                                title: Text(item.exercise.title),
                                                subtitle: Text(
                                                  'Gespielt am ${item.dayName} • Ergebnis: $resultVal',
                                                  style: const TextStyle(
                                                      color: Colors.green,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                trailing: IconButton(
                                                  icon: const Icon(
                                                      Icons.show_chart,
                                                      color: Colors.blue),
                                                  onPressed: () {
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            ExerciseHistoryScreen(
                                                          exercise: item.exercise,
                                                          playerId: widget.user.uid,
                                                        ),
                                                      ),
                                                    );
                                                  },
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

class _DashboardExerciseItem {
  final Exercise exercise;
  final String dayName;
  final DateTime scheduledDate;
  final ExerciseResult? result;
  final bool isOverdue;

  _DashboardExerciseItem({
    required this.exercise,
    required this.dayName,
    required this.scheduledDate,
    this.result,
    required this.isOverdue,
  });
}