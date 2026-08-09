import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/performance_test_model.dart';

/// Firestore-Service zur Verwaltung von Leistungstests, Zuweisungen und Einzelergebnissen.
class TestService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // 1. LEISTUNGSTEST-VORLAGEN (TEMPLATES)
  // ---------------------------------------------------------------------------

  /// Erstellt eine neue Testvorlage in Firestore.
  Future<void> createTestTemplate(PerformanceTest test) async {
    await _db.collection('performance_tests').add(test.toMap());
  }

  /// Aktualisiert eine bestehende Testvorlage (Titel, Beschreibung, Übungs-IDs).
  Future<void> updateTestTemplate(PerformanceTest test) async {
    await _db
        .collection('performance_tests')
        .doc(test.id)
        .update(test.toMap());
  }

  /// Löscht eine Testvorlage anhand ihrer ID aus Firestore.
  Future<void> deleteTestTemplate(String testId) async {
    await _db.collection('performance_tests').doc(testId).delete();
  }

  /// Liest alle Leistungstests-Vorlagen als Live-Stream aus.
  Stream<List<PerformanceTest>> getTestTemplates() {
    return _db.collection('performance_tests').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => PerformanceTest.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // ---------------------------------------------------------------------------
  // 2. WOCHENPLAN-ZUWEISUNGEN (ASSIGNMENTS)
  // ---------------------------------------------------------------------------

  /// Weist einem Spieler für eine bestimmte Kalenderwoche einen Leistungstest zu.
  /// Überschreibt alte Zuweisungen für dieselbe Woche.
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

  /// Holt den zugewiesenen Test eines Spielers für eine bestimmte Kalenderwoche.
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

  // ---------------------------------------------------------------------------
  // 3. TESTERGEBNISSE & NOTIZEN (RESULTS)
  // ---------------------------------------------------------------------------

  /// Speichert ein neu abgeschlossenes Testergebnis inkl. Notiz.
  Future<void> saveTestResult(PerformanceTestResult result) async {
    await _db.collection('test_results').add(result.toMap());
  }

  /// Aktualisiert ein bestehendes Testergebnis (z. B. zum Bearbeiten der Notiz).
  Future<void> updateTestResult(PerformanceTestResult result) async {
    await _db
        .collection('test_results')
        .doc(result.id)
        .update(result.toMap());
  }

  /// Löscht ein Testergebnis aus der Datenbank.
  Future<void> deleteTestResult(String resultId) async {
    await _db.collection('test_results').doc(resultId).delete();
  }

  /// Liest alle Testergebnisse eines bestimmten Leistungstests für einen Spieler aus (sortiert nach Datum).
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

  /// Liest ALLE Testergebnisse eines Spielers über alle Tests hinweg aus.
  Stream<List<PerformanceTestResult>> getAllResultsForPlayer(String playerId) {
    return _db
        .collection('test_results')
        .where('playerId', isEqualTo: playerId)
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