/// Zentrale Hilfsklasse für Datums- und Zeitformatierungen in der gesamten App.
class DateUtilsHelper {
  /// Formatiert ein [DateTime]-Objekt in ein lesbares Format (z. B. "11.08.2026, 18:30 Uhr")
  static String formatTimestamp(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day.$month.$year, $hour:$minute Uhr';
  }

  /// Formatiert nur das Datum ohne Uhrzeit (z. B. "11.08.2026")
  static String formatDateOnly(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    return '$day.$month.$year';
  }

  /// Formatiert nur die Uhrzeit (z. B. "18:30 Uhr")
  static String formatTimeOnly(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute Uhr';
  }
}