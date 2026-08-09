import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Service-Klasse zur Verwaltung aller Benutzerdaten in Cloud Firestore
class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ===========================================================================
  // NEU: Einzelne Benutzer-Abfragen für die main.dart
  // ===========================================================================

  /// Liefert die Daten eines einzelnen Benutzers als Live-Stream zurück.
  /// Wird in main.dart verwendet, um die Rolle (Spieler/Trainer) dynamisch zu bestimmen.
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
  // Profil-Bearbeitung & Verwaltung
  // ===========================================================================

  /// Profil-Updates
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
    await _db.collection('users').doc(playerId).update({'trainerId': trainerId});
  }

  /// Entfernt die Trainerzuweisung eines Spielers
  Future<void> removePlayerFromTrainer(String playerId) async {
    await _db.collection('users').doc(playerId).update({'trainerId': FieldValue.delete()});
  }

  /// Stream aller Spieler, die einem bestimmten Trainer zugewiesen sind
  Stream<List<AppUser>> getPlayersForTrainer(String trainerId) {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AppUser.fromMap(doc.data(), doc.id))
          .where((user) => !user.isTrainer && user.trainerId == trainerId && user.approved)
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
      }).toList();
    });
  }
}