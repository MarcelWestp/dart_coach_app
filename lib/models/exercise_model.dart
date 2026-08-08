enum MetricType { score, hitsAndAttempts, timeInSeconds }

/// Erweitertes Übungsmodell mit Unterstützung für Tag-IDs
class Exercise {
  final String id;
  final String title;
  final String description;
  final MetricType metricType;
  final List<String> tagIds; // NEU: Liste zugewiesener Tag-IDs

  Exercise({
    required this.id,
    required this.title,
    required this.description,
    required this.metricType,
    List<String>? tagIds,
  }) : tagIds = tagIds ?? [];

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'metricType': metricType.name,
      'tagIds': tagIds,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map, String docId) {
    return Exercise(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      metricType: MetricType.values.firstWhere(
        (e) => e.name == map['metricType'],
        orElse: () => MetricType.score,
      ),
      tagIds: List<String>.from(map['tagIds'] ?? []),
    );
  }
}