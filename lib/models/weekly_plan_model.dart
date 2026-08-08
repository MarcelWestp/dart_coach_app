/// Zuordnung von Übungen zu einzelnen Wochentagen
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