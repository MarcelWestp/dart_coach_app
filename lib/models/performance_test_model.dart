import 'package:cloud_firestore/cloud_firestore.dart';

/// Vorlage / Template für einen Leistungstest (bestehend aus mehreren Übungen)
class PerformanceTest {
  final String id;
  final String title;
  final String description;
  final List<String> exerciseIds; // Liste der Übungs-IDs, die diesem Test angehören

  PerformanceTest({
    required this.id,
    required this.title,
    required this.description,
    required this.exerciseIds,
  });

  /// Erstellt eine Kopie des Objekts mit optional geänderten Feldern (für einfache Bearbeitung)
  PerformanceTest copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? exerciseIds,
  }) {
    return PerformanceTest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      exerciseIds: exerciseIds ?? this.exerciseIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'exerciseIds': exerciseIds,
    };
  }

  factory PerformanceTest.fromMap(Map<String, dynamic> map, String docId) {
    return PerformanceTest(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      exerciseIds: List<String>.from(map['exerciseIds'] ?? []),
    );
  }
}

/// Zuweisung eines Leistungstests an einen Spieler für eine bestimmte Kalenderwoche
class AssignedTest {
  final String id;
  final String playerId;
  final String trainerId;
  final String testId;
  final int year;
  final int weekNumber;

  AssignedTest({
    required this.id,
    required this.playerId,
    required this.trainerId,
    required this.testId,
    required this.year,
    required this.weekNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'playerId': playerId,
      'trainerId': trainerId,
      'testId': testId,
      'year': year,
      'weekNumber': weekNumber,
    };
  }

  factory AssignedTest.fromMap(Map<String, dynamic> map, String docId) {
    return AssignedTest(
      id: docId,
      playerId: map['playerId'] ?? '',
      trainerId: map['trainerId'] ?? '',
      testId: map['testId'] ?? '',
      year: map['year'] ?? DateTime.now().year,
      weekNumber: map['weekNumber'] ?? 1,
    );
  }
}

/// Absolviertes Ergebnis eines Leistungstests mit allen Einzelergebnissen je Übung & Notiz
class PerformanceTestResult {
  final String id;
  final String playerId;
  final String testId;
  final String testTitle;
  final Map<String, int> exerciseScores; // Key: exerciseId, Value: Erreichte Punkte
  final int totalScore;                  // Automatisch berechnete Gesamtsumme
  final int durationInSeconds;           // Stoppuhr-Dauer des gesamten Tests
  final String? note;                    // NEU: Gesamt-Notiz zum Test
  final DateTime timestamp;

  PerformanceTestResult({
    required this.id,
    required this.playerId,
    required this.testId,
    required this.testTitle,
    required this.exerciseScores,
    required this.totalScore,
    required this.durationInSeconds,
    this.note,
    required this.timestamp,
  });

  /// Erstellt eine Kopie des Objekts für spätere Notiz-Bearbeitung oder Korrekturen
  PerformanceTestResult copyWith({
    String? id,
    String? playerId,
    String? testId,
    String? testTitle,
    Map<String, int>? exerciseScores,
    int? totalScore,
    int? durationInSeconds,
    String? note,
    DateTime? timestamp,
  }) {
    return PerformanceTestResult(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      testId: testId ?? this.testId,
      testTitle: testTitle ?? this.testTitle,
      exerciseScores: exerciseScores ?? this.exerciseScores,
      totalScore: totalScore ?? this.totalScore,
      durationInSeconds: durationInSeconds ?? this.durationInSeconds,
      note: note ?? this.note,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'playerId': playerId,
      'testId': testId,
      'testTitle': testTitle,
      'exerciseScores': exerciseScores,
      'totalScore': totalScore,
      'durationInSeconds': durationInSeconds,
      'note': note ?? '', // NEU: Notiz speichern
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory PerformanceTestResult.fromMap(Map<String, dynamic> map, String docId) {
    final Map<String, dynamic> rawScores = map['exerciseScores'] ?? {};
    final Map<String, int> parsedScores = rawScores.map(
      (key, value) => MapEntry(key, (value as num).toInt()),
    );

    return PerformanceTestResult(
      id: docId,
      playerId: map['playerId'] ?? '',
      testId: map['testId'] ?? '',
      testTitle: map['testTitle'] ?? '',
      exerciseScores: parsedScores,
      totalScore: map['totalScore'] ?? 0,
      durationInSeconds: map['durationInSeconds'] ?? 0,
      note: map['note'], // NEU: Notiz auslesen
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}