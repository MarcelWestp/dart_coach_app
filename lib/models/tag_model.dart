import 'package:flutter/material.dart';

/// Modell für ein Übungs-Tag (Schlagwort)
class ExerciseTag {
  final String id;
  final String name;
  final int colorValue; // Speichert den Farbwert als Integer (0xFF...)

  ExerciseTag({
    required this.id,
    required this.name,
    required this.colorValue,
  });

  /// Konvertiert die Zahl in ein Flutter Color-Objekt
  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'colorValue': colorValue,
    };
  }

  factory ExerciseTag.fromMap(Map<String, dynamic> map, String docId) {
    return ExerciseTag(
      id: docId,
      name: map['name'] ?? '',
      colorValue: map['colorValue'] ?? Colors.deepOrange.value,
    );
  }
}