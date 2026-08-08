import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/performance_test_model.dart';

/// Firestore-Service zur Verwaltung von Leistungstests und Einzelergebnissen
class TestService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Erstellt eine neue Testvorlage
  Future<void> createTestTemplate(PerformanceTest test) async {
    await _db.collection('performance_tests').add(test.toMap());
  }

  /// Liest alle Leistungstests aus
  Stream<List<PerformanceTest>> getTestTemplates() {
    return _db.collection('performance_tests').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => PerformanceTest.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Weist einem Spieler für eine KW einen Leistungstest zu
  Future<void> assignTestToPlayer(AssignedTest assignment) async {
    final existing = await _db
        .collection('assigned_tests')
        .where('playerId', isEqualTo: assignment.playerId)
        .where('year', isEqualTo: assignment.year)
        .where('weekNumber', isEqualTo: assignment.weekNumber)
        .get();

    for (var doc in existing.docs) {
      await doc.reference.delete();
    }

    await _db.collection('assigned_tests').add(assignment.toMap());
  }

  /// Holt den zugewiesenen Test für die Woche
  Stream<AssignedTest?> getAssignedTestForWeek(
      String playerId, int year, int weekNumber) {
    return _db
        .collection('assigned_tests')
        .where('playerId', isEqualTo: playerId)
        .where('year', isEqualTo: year)
        .where('weekNumber', isEqualTo: weekNumber)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return AssignedTest.fromMap(
            snapshot.docs.first.data(), snapshot.docs.first.id);
      }
      return null;
    });
  }

  /// Speichert ein abgeschlossenes Testergebnis
  Future<void> saveTestResult(PerformanceTestResult result) async {
    await _db.collection('test_results').add(result.toMap());
  }

  /// Liest alle Testergebnisse eines bestimmten Leistungstests für einen Spieler aus
  Stream<List<PerformanceTestResult>> getResultsForPlayerAndTest(
      String playerId, String testId) {
    return _db
        .collection('test_results')
        .where('playerId', isEqualTo: playerId)
        .where('testId', isEqualTo: testId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => PerformanceTestResult.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }
}