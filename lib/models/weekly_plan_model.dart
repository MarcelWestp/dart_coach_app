/// Art der Übungsvorgabe im Wochenplan
enum TargetType { none, duration, reps }

/// Einzelne eingeplante Übung mit optionaler Zielvorgabe (Dauer oder Wiederholungen)
class ScheduledExercise {
  final String exerciseId;
  final TargetType targetType;
  final String targetValue; // z. B. "15 Min" oder "5 Serien"

  ScheduledExercise({
    required this.exerciseId,
    this.targetType = TargetType.none,
    this.targetValue = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'targetType': targetType.name,
      'targetValue': targetValue,
    };
  }

  factory ScheduledExercise.fromMap(Map<String, dynamic> map) {
    return ScheduledExercise(
      exerciseId: map['exerciseId'] ?? '',
      targetType: TargetType.values.firstWhere(
        (e) => e.name == map['targetType'],
        orElse: () => TargetType.none,
      ),
      targetValue: map['targetValue'] ?? '',
    );
  }
}

/// Tagesplan eines Spielers mit einer Liste zugewiesener ScheduledExercises
class DailySchedule {
  final String dayOfWeek;
  final List<ScheduledExercise> scheduledExercises;

  DailySchedule({
    required this.dayOfWeek,
    required this.scheduledExercises,
  });

  Map<String, dynamic> toMap() {
    return {
      'dayOfWeek': dayOfWeek,
      'scheduledExercises': scheduledExercises.map((e) => e.toMap()).toList(),
    };
  }

  factory DailySchedule.fromMap(Map<String, dynamic> map) {
    // Abwärtskompatibilität: Falls alte Daten noch als 'exerciseIds' (List<String>) gespeichert waren
    List<ScheduledExercise> items = [];
    if (map['scheduledExercises'] != null) {
      items = (map['scheduledExercises'] as List)
          .map((item) => ScheduledExercise.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } else if (map['exerciseIds'] != null) {
      items = (map['exerciseIds'] as List)
          .map((id) => ScheduledExercise(exerciseId: id.toString()))
          .toList();
    }

    return DailySchedule(
      dayOfWeek: map['dayOfWeek'] ?? '',
      scheduledExercises: items,
    );
  }
}

/// Vollständiger Wochen-Trainingsplan
class TrainingPlan {
  final String id;
  final String title;
  final String playerId;
  final String trainerId;
  final int year;
  final int weekNumber;
  final List<DailySchedule> days;

  TrainingPlan({
    required this.id,
    required this.title,
    required this.playerId,
    required this.trainerId,
    required this.year,
    required this.weekNumber,
    required this.days,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'playerId': playerId,
      'trainerId': trainerId,
      'year': year,
      'weekNumber': weekNumber,
      'days': days.map((d) => d.toMap()).toList(),
    };
  }

  factory TrainingPlan.fromMap(Map<String, dynamic> map, String docId) {
    return TrainingPlan(
      id: docId,
      title: map['title'] ?? '',
      playerId: map['playerId'] ?? '',
      trainerId: map['trainerId'] ?? '',
      year: map['year'] ?? DateTime.now().year,
      weekNumber: map['weekNumber'] ?? 1,
      days: map['days'] != null
          ? (map['days'] as List)
              .map((d) => DailySchedule.fromMap(Map<String, dynamic>.from(d)))
              .toList()
          : [],
    );
  }
}