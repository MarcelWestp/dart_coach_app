import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/weekly_plan_model.dart';

/// Service zur Verwaltung der kalenderwochenbasierten Trainingspläne in Firestore
class PlanService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Erstellt eine eindeutige Dokument-ID für eine bestimmte Woche eines Spielers
  String _getDocId(String playerId, int year, int weekNumber) {
    return '${playerId}_${year}_KW$weekNumber';
  }

  /// Speichert oder aktualisiert den Trainingsplan für eine spezifische Kalenderwoche
  Future<void> saveTrainingPlan(TrainingPlan plan) async {
    try {
      final docId = _getDocId(plan.playerId, plan.year, plan.weekNumber);
      await _db
          .collection('training_plans')
          .doc(docId)
          .set(plan.toMap());
    } catch (e) {
      print('Fehler beim Speichern des Trainingsplans: $e');
      rethrow;
    }
  }

  /// Lädt den Trainingsplan eines Spielers für eine spezifische Woche in Echtzeit
  Stream<TrainingPlan?> getPlanForPlayerAndWeek(
    String playerId,
    int year,
    int weekNumber,
  ) {
    final docId = _getDocId(playerId, year, weekNumber);
    return _db
        .collection('training_plans')
        .doc(docId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return TrainingPlan.fromMap(snapshot.data()!, snapshot.id);
      }
      return null;
    });
  }
}