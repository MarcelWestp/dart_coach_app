/// Art der Übungsvorgabe im Wochenplan
enum TargetType { none, duration, reps }

/// Einzelne eingeplante Übung mit optionaler Zielvorgabe (Dauer oder Wiederholungen)
class ScheduledExercise {
  final String exerciseId;
  final TargetType targetType;
  final String targetValue; // z. B. "15 Min" oder "5 Serien"
  final String? note;

  ScheduledExercise({
    required this.exerciseId,
    this.targetType = TargetType.none,
    this.targetValue = '',
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'targetType': targetType.name,
      'targetValue': targetValue,
      'note': note,
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
      note: map['note'],
    );
  }
}

/// Tagesplan eines Spielers mit einer Liste zugewiesener ScheduledExercises
class DailySchedule {
  final String dayOfWeek; // z.B. "Montag", "Dienstag"
  final List<String> exerciseIds; // IDs der zugewiesenen Übungen

  DailySchedule({
    required this.dayOfWeek,
    required this.exerciseIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'dayOfWeek': dayOfWeek,
      'exerciseIds': exerciseIds,
    };
  }

  factory DailySchedule.fromMap(Map<String, dynamic> map) {
    return DailySchedule(
      dayOfWeek: map['dayOfWeek'] ?? '',
      exerciseIds: List<String>.from(map['exerciseIds'] ?? []),
    );
  }
}

/// Modell für einen Wochen-Trainingsplan (inkl. Kalenderwoche und Jahr)
class TrainingPlan {
  final String id;
  final String title;
  final String playerId;   // Für welchen Spieler?
  final String trainerId;  // Wer hat den Plan erstellt?
  final int year;          // z. B. 2026
  final int weekNumber;    // z. B. Kalenderwoche 32
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
      days: (map['days'] as List<dynamic>?)
              ?.map((d) => DailySchedule.fromMap(d))
              .toList() ??
          [],
    );
  }
}