import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tag_model.dart';

/// Firestore-Service zur Verwaltung globaler Übungs-Tags
class TagService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Erstellt ein neues Tag
  Future<void> createTag(ExerciseTag tag) async {
    await _db.collection('tags').add(tag.toMap());
  }

  /// Aktualisiert ein bestehendes Tag
  Future<void> updateTag(ExerciseTag tag) async {
    await _db.collection('tags').doc(tag.id).update(tag.toMap());
  }

  /// Löscht ein Tag aus Firestore
  Future<void> deleteTag(String tagId) async {
    await _db.collection('tags').doc(tagId).delete();
  }

  /// Liest alle Tags in Echtzeit aus
  Stream<List<ExerciseTag>> getTags() {
    return _db.collection('tags').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ExerciseTag.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
}