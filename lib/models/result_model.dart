import 'package:cloud_firestore/cloud_firestore.dart';

/// Modell für ein absolviertes Trainingsergebnis
class ExerciseResult {
  final String id;
  final String playerId;
  final String exerciseId;
  final DateTime timestamp;
  
  // Verschiedene Auswertungswerte (je nach MetricType)
  final int? score;           // Z.B. Punkte bei MetricType.score
  final int? hits;            // Z.B. Treffer bei MetricType.hitsAndAttempts
  final int? attempts;        // Z.B. Versuche bei MetricType.hitsAndAttempts
  final int? timeInSeconds;   // Z.B. Benötigte Zeit bei MetricType.timeInSeconds

  ExerciseResult({
    required this.id,
    required this.playerId,
    required this.exerciseId,
    required this.timestamp,
    this.score,
    this.hits,
    this.attempts,
    this.timeInSeconds,
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
    };
  }

  factory ExerciseResult.fromMap(Map<String, dynamic> map, String docId) {
    return ExerciseResult(
      id: docId,
      playerId: map['playerId'] ?? '',
      exerciseId: map['exerciseId'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      score: map['score'],
      hits: map['hits'],
      attempts: map['attempts'],
      timeInSeconds: map['timeInSeconds'],
    );
  }
}