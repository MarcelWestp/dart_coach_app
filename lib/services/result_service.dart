import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/result_model.dart';

/// Service zum Speichern, Aktualisieren und Auslesen der Trainingsergebnisse
class ResultService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Speichert ein neues absolviertes Ergebnis in Firestore
  Future<void> saveResult(ExerciseResult result) async {
    try {
      await _db.collection('results').add(result.toMap());
    } catch (e) {
      print('Fehler beim Speichern des Ergebnisses: $e');
      rethrow;
    }
  }

  /// Aktualisiert ein bereits bestehendes Ergebnis in Firestore (Korrektur)
  Future<void> updateResult(ExerciseResult result) async {
    try {
      await _db.collection('results').doc(result.id).update(result.toMap());
    } catch (e) {
      print('Fehler beim Aktualisieren des Ergebnisses: $e');
      rethrow;
    }
  }

  /// Holt alle Ergebnisse eines bestimmten Spielers in Echtzeit
  Stream<List<ExerciseResult>> getResultsForPlayer(String playerId) {
    return _db
        .collection('results')
        .where('playerId', isEqualTo: playerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ExerciseResult.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Holt alle Ergebnisse eines bestimmten Spielers für eine bestimmte Übung
  Stream<List<ExerciseResult>> getResultsForExercise(
      String playerId, String exerciseId) {
    return _db
        .collection('results')
        .where('playerId', isEqualTo: playerId)
        .where('exerciseId', isEqualTo: exerciseId)
        .snapshots()
        .map((snapshot) {
      final results = snapshot.docs
          .map((doc) => ExerciseResult.fromMap(doc.data(), doc.id))
          .toList();
      results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return results;
    });
  }
}