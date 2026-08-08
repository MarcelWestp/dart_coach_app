import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise_model.dart';

/// Firestore-Service zur Verwaltung von Übungen (CRUD)
class ExerciseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Erstellt eine neue Übung in Firestore
  Future<void> createExercise(Exercise exercise) async {
    try {
      await _db.collection('exercises').add(exercise.toMap());
    } catch (e) {
      print('Fehler beim Erstellen der Übung: $e');
      rethrow;
    }
  }

  /// KORREKTUR: Aktualisiert eine bestehende Übung in Firestore
  Future<void> updateExercise(Exercise exercise) async {
    try {
      await _db.collection('exercises').doc(exercise.id).update(exercise.toMap());
    } catch (e) {
      print('Fehler beim Aktualisieren der Übung: $e');
      rethrow;
    }
  }

  /// KORREKTUR: Löscht eine Übung aus Firestore
  Future<void> deleteExercise(String exerciseId) async {
    try {
      await _db.collection('exercises').doc(exerciseId).delete();
    } catch (e) {
      print('Fehler beim Löschen der Übung: $e');
      rethrow;
    }
  }

  /// Liest alle Übungen in Echtzeit aus Firestore aus
  Stream<List<Exercise>> getExercises() {
    return _db.collection('exercises').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Exercise.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
}