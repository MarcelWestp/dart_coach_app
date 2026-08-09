import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Service-Klasse zur Verwaltung aller Benutzerdaten in Cloud Firestore
class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ===========================================================================
  // Einzelne Benutzer-Abfragen
  // ===========================================================================

  /// Liefert die Daten eines einzelnen Benutzers als Live-Stream zurück.
  /// Wird z. B. in main.dart und im UserProfileDetailScreen verwendet.
  Stream<AppUser?> getUserDataStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return AppUser.fromMap(snapshot.data()!, snapshot.id);
      }
      return null;
    });
  }

  /// Einmalige Abfrage der Benutzerdaten über Future
  Future<AppUser?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return AppUser.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // ===========================================================================
  // NEU: Nutzer-Suche & Filterung für den UserSearchScreen
  // ===========================================================================

  /// Stream aller bestätigten Nutzer für die Suche.
  /// Filtert nach eingegebenem Suchtext (Name, Verein, Team) und Rolle (Spieler/Trainer).
  Stream<List<AppUser>> searchUsers({
    String query = '',
    String? roleFilter = 'all',
  }) {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => AppUser.fromMap(doc.data(), doc.id)).where((
        user,
      ) {
        // Nur freigeschaltete Nutzer anzeigen
        if (!user.approved) return false;

        // 1. Rollen-Filter
        if (roleFilter != null && roleFilter != 'all') {
          if (roleFilter == 'trainer' && !user.isTrainer) return false;
          if (roleFilter == 'player' && user.isTrainer) return false;
        }

        // 2. Textsuche nach Name, Verein oder Team (Groß-/Kleinschreibung ignorieren)
        if (query.trim().isEmpty) return true;
        final q = query.toLowerCase().trim();

        final nameMatch = user.name.toLowerCase().contains(q);
        final clubMatch = user.club?.toLowerCase().contains(q) ?? false;
        final teamMatch = user.team?.toLowerCase().contains(q) ?? false;

        return nameMatch || clubMatch || teamMatch;
      }).toList();
    });
  }

  // ===========================================================================
  // Profil-Bearbeitung & Verwaltung
  // ===========================================================================

  /// Profil-Updates (z. B. Stammdaten, Equipment, Privatsphäre-Status)
  Future<void> updateUserProfile(AppUser user) async {
    await _db.collection('users').doc(user.uid).update(user.toMap());
  }

  /// Schaltet einen neuen Benutzer frei (approved = true)
  Future<void> approveUser(String userId) async {
    await _db.collection('users').doc(userId).update({'approved': true});
  }

  /// Entfernt/Löscht ein Mitglied aus Firestore
  Future<void> deleteUser(String userId) async {
    await _db.collection('users').doc(userId).delete();
  }

  // ===========================================================================
  // Streams für Freigaben & Mitgliederlisten
  // ===========================================================================

  /// Stream aller ausstehenden Anfragen (approved == false)
  Stream<List<AppUser>> getPendingUsers() {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AppUser.fromMap(doc.data(), doc.id))
          .where((user) => !user.approved)
          .toList();
    });
  }

  /// Stream aller bestätigten Mitglieder (approved == true)
  Stream<List<AppUser>> getApprovedUsers() {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AppUser.fromMap(doc.data(), doc.id))
          .where((user) => user.approved)
          .toList();
    });
  }

  // ===========================================================================
  // Zuweisungs-Methoden für Trainer & Kader
  // ===========================================================================

  /// Weist einem Spieler einen Trainer zu
  Future<void> assignPlayerToTrainer(String playerId, String trainerId) async {
    await _db.collection('users').doc(playerId).update({
      'trainerId': trainerId,
    });
  }

  /// Entfernt die Trainerzuweisung eines Spielers
  Future<void> removePlayerFromTrainer(String playerId) async {
    await _db.collection('users').doc(playerId).update({
      'trainerId': FieldValue.delete(),
    });
  }

  /// Stream aller Spieler, die einem bestimmten Trainer zugewiesen sind
  Stream<List<AppUser>> getPlayersForTrainer(String trainerId) {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AppUser.fromMap(doc.data(), doc.id))
          .where(
            (user) =>
                !user.isTrainer && user.trainerId == trainerId && user.approved,
          )
          .toList();
    });
  }

  /// Stream aller freigeschalteten Spieler ohne zugewiesenen Trainer
  Stream<List<AppUser>> getUnassignedPlayers() {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AppUser.fromMap(doc.data(), doc.id))
          .where((user) {
            final bool isPlayer = !user.isTrainer;
            final bool hasNoTrainer =
                user.trainerId == null || user.trainerId!.trim().isEmpty;
            return isPlayer && hasNoTrainer && user.approved;
          })
          .toList();
    });
  }

  /// Berechnet die Anzahl absolvierter Übungen für einen Nutzer (Gesamt, dieser Monat, diese Woche)
  Stream<Map<String, int>> getUserExerciseStats(String userId) {
    return _db
        .collection('results')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final now = DateTime.now();
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final beginningOfWeek = DateTime(
            startOfWeek.year,
            startOfWeek.month,
            startOfWeek.day,
          );
          final beginningOfMonth = DateTime(now.year, now.month, 1);

          int totalCount = 0;
          int monthCount = 0;
          int weekCount = 0;

          for (var doc in snapshot.docs) {
            final data = doc.data();
            if (data['timestamp'] != null) {
              final DateTime date = (data['timestamp'] as Timestamp).toDate();
              totalCount++;

              if (date.isAfter(beginningOfMonth)) {
                monthCount++;
              }
              if (date.isAfter(beginningOfWeek)) {
                weekCount++;
              }
            }
          }

          return {'total': totalCount, 'month': monthCount, 'week': weekCount};
        });
  }
}
