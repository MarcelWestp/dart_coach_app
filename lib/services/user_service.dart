import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  /// Zuweisungs-Methoden für Trainer & Kader
  Future<void> assignPlayerToTrainer(String playerId, String trainerId) async {
    await _db.collection('users').doc(playerId).update({'trainerId': trainerId});
  }

  Future<void> removePlayerFromTrainer(String playerId) async {
    await _db.collection('users').doc(playerId).update({'trainerId': FieldValue.delete()});
  }

  Stream<List<AppUser>> getPlayersForTrainer(String trainerId) {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AppUser.fromMap(doc.data(), doc.id))
          .where((user) => !user.isTrainer && user.trainerId == trainerId && user.approved)
          .toList();
    });
  }

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