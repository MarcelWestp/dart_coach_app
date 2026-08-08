import 'package:cloud_firestore/cloud_firestore.dart';

/// Datenmodell für das erzielte Ergebnis einer Übung
class ExerciseResult {
  final String id;
  final String playerId;
  final String exerciseId;
  final DateTime timestamp;
  final int? score;
  final int? hits;
  final int? attempts;
  final int? timeInSeconds;

  // Zuordnung zum Wochenplan
  final String? dayOfWeek; // z. B. "Montag"
  final int? weekNumber;  // z. B. 32
  final int? year;        // z. B. 2026
  
  // NEU: Welcher Durchlauf war dies? (z. B. 1, 2, 3)
  final int? roundIndex;

  // Notiz vom Spieler zur Übung
  final String? playerNote;

  ExerciseResult({
    required this.id,
    required this.playerId,
    required this.exerciseId,
    required this.timestamp,
    this.score,
    this.hits,
    this.attempts,
    this.timeInSeconds,
    this.dayOfWeek,
    this.weekNumber,
    this.year,
    this.roundIndex,
    this.playerNote,
  });

  Map<String, dynamic> toMap() {
    return {
      'playerId': playerId,
      'exerciseId': exerciseId,
      'timestamp': Timestamp.fromDate(timestamp),
      'score': score,
      'hits': hits,
      'attempts': attempts,
      'timeInSeconds': timeInSeconds,
      'dayOfWeek': dayOfWeek,
      'weekNumber': weekNumber,
      'year': year,
      'roundIndex': roundIndex,
      'playerNote': playerNote,
    };
  }

  factory ExerciseResult.fromMap(Map<String, dynamic> map, String docId) {
    return ExerciseResult(
      id: docId,
      playerId: map['playerId'] ?? '',
      exerciseId: map['exerciseId'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      score: map['score'],
      hits: map['hits'],
      attempts: map['attempts'],
      timeInSeconds: map['timeInSeconds'],
      dayOfWeek: map['dayOfWeek'],
      weekNumber: map['weekNumber'],
      year: map['year'],
      roundIndex: map['roundIndex'],
      playerNote: map['playerNote'],
    );
  }
}