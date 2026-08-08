import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Registriert einen neuen Benutzer in Firebase Auth und speichert die Daten in Firestore
  Future<UserCredential?> registerUser({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String roleString = role == UserRole.trainer ? 'trainer' : 'player';
      final bool isTrainerFlag = role == UserRole.trainer;

      AppUser newUser = AppUser(
        uid: credential.user!.uid,
        name: name,
        email: email,
        role: roleString,
        isTrainer: isTrainerFlag,
        approved: false, // Standardmäßig muss der User freigeschaltet werden
      );

      await _db
          .collection('users')
          .doc(credential.user!.uid)
          .set(newUser.toMap());

      return credential;
    } catch (e) {
      print('Fehler bei der Registrierung: $e');
      rethrow;
    }
  }

  /// Meldet einen Benutzer an
  Future<UserCredential?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Fehler beim Login: $e');
      rethrow;
    }
  }

  /// Meldet den aktuellen Benutzer ab
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// NEU: Sendet eine E-Mail zum Zurücksetzen des Passworts
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Fehler beim Senden der Passwort-E-Mail: $e');
      rethrow;
    }
  }

  /// NEU: Ändert das Passwort des aktuell angemeldeten Benutzers
  Future<void> updatePassword(String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      } else {
        throw Exception('Kein angemeldeter Benutzer gefunden.');
      }
    } catch (e) {
      print('Fehler beim Aktualisieren des Passworts: $e');
      rethrow;
    }
  }

  /// Holt das AppUser-Profil eines Benutzers aus Firestore
  Future<AppUser?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Fehler beim Laden des Benutzerprofils: $e');
      return null;
    }
  }
}