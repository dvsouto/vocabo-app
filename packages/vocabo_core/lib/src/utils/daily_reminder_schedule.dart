/// Decides when the daily review reminder fires. The app stays resident in
/// the menu bar, so it checks periodically instead of scheduling with the OS,
/// which keeps the due count in the notification accurate.
abstract final class DailyReminderSchedule {
  static final _timePattern = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');

  /// Today's reminder moment for a `HH:MM` time, or null when invalid.
  static DateTime? reminderAt(String time, DateTime now) {
    final match = _timePattern.firstMatch(time);
    if (match == null) return null;
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
    );
  }

  static bool shouldNotify({
    required bool enabled,
    required String time,
    required DateTime now,
    DateTime? lastNotifiedOn,
  }) {
    if (!enabled) return false;
    final reminderAt = DailyReminderSchedule.reminderAt(time, now);
    if (reminderAt == null || now.isBefore(reminderAt)) return false;
    return lastNotifiedOn == null || !isSameDay(lastNotifiedOn, now);
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String format(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
