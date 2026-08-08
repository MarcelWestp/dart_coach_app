import '../models/weekly_plan_model.dart'; // Für TargetType (none, duration, reps)

/// Der Typ der Erfassungsmethode einer Übung
enum MetricType { score, hitsAndAttempts, timeInSeconds }

/// Das Datenmodell für eine Stamm-Übung
class Exercise {
  final String id;
  final String title;
  final String description;
  final MetricType metricType;
  final List<String> tagIds;
  
  // NEU: Optionale Standard-Vorgabe für Dauer oder Durchläufe
  final TargetType defaultTargetType;
  final String defaultTargetValue; // z. B. "15 Min" oder "10 Serien"

  Exercise({
    required this.id,
    required this.title,
    required this.description,
    required this.metricType,
    this.tagIds = const [],
    this.defaultTargetType = TargetType.none,
    this.defaultTargetValue = '',
  });

  /// Konvertiert das Objekt in ein Map-Format für Cloud Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'metricType': metricType.name,
      'tagIds': tagIds,
      'defaultTargetType': defaultTargetType.name,
      'defaultTargetValue': defaultTargetValue,
    };
  }

  /// Erstellt ein Exercise-Objekt aus einem Firestore-Dokument
  factory Exercise.fromMap(Map<String, dynamic> map, String docId) {
    return Exercise(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      metricType: MetricType.values.firstWhere(
        (e) => e.name == map['metricType'],
        orElse: () => MetricType.score,
      ),
      tagIds: map['tagIds'] != null ? List<String>.from(map['tagIds']) : [],
      defaultTargetType: TargetType.values.firstWhere(
        (e) => e.name == map['defaultTargetType'],
        orElse: () => TargetType.none,
      ),
      defaultTargetValue: map['defaultTargetValue'] ?? '',
    );
  }
}