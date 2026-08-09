import '../../models/exercise_model.dart';
import '../../models/result_model.dart';
import '../../models/weekly_plan_model.dart';

/// Hilfsklasse zur Bündelung aller Informationen eines Dashboard-Eintrags für Spieler
class DashboardExerciseItem {
  final Exercise exercise;
  final String dayName;
  final DateTime scheduledDate;
  final ExerciseResult? result;
  final bool isOverdue;
  final String targetInfo;

  // Vorgabe-Typ und -Wert für Durchläufe/Dauer
  final TargetType targetType;
  final String targetValue;

  // Notiz des Trainers für diese Übung
  final String? trainerNote;

  DashboardExerciseItem({
    required this.exercise,
    required this.dayName,
    required this.scheduledDate,
    this.result,
    required this.isOverdue,
    this.targetInfo = '',
    this.targetType = TargetType.none,
    this.targetValue = '',
    this.trainerNote,
  });
}