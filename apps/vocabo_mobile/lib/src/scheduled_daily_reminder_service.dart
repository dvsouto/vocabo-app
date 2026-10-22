import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:vocabo_app/vocabo_app.dart';
import 'package:vocabo_core/vocabo_core.dart';

/// The phone version of the daily reminder: the app is not resident, so
/// besides the in-app check it schedules a repeating notification with the
/// system at the chosen time.
class ScheduledDailyReminderService extends DailyReminderService {
  ScheduledDailyReminderService({
    required super.loadPreferences,
    required super.loadStatus,
    required super.onOpen,
    required super.loadLocalizations,
    FlutterLocalNotificationsPlugin? notifications,
  }) : _plugin = notifications ?? FlutterLocalNotificationsPlugin(),
       super(notifications: notifications ?? FlutterLocalNotificationsPlugin());

  static const _scheduledId = 1002;
  static bool _timezoneReady = false;

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> start() async {
    await super.start();
    await reschedule();
  }

  static Future<void> _ensureTimezone() async {
    if (_timezoneReady) return;
    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e, st) {
      appLogger.handle(e, st, 'Could not read the device time zone');
    }
    _timezoneReady = true;
  }

  /// Replaces the system schedule with the current preference.
  Future<void> reschedule() async {
    try {
      await _plugin.cancel(id: _scheduledId);
      final preferences = loadPreferences();
      if (preferences == null || !preferences.dailyReminderEnabled) return;
      final at = DailyReminderSchedule.reminderAt(
        preferences.dailyReminderTime,
        DateTime.now(),
      );
      if (at == null) return;

      await _ensureTimezone();
      var moment = tz.TZDateTime(
        tz.local,
        at.year,
        at.month,
        at.day,
        at.hour,
        at.minute,
      );
      if (moment.isBefore(tz.TZDateTime.now(tz.local))) {
        moment = moment.add(const Duration(days: 1));
      }
      final l10n = loadLocalizations();
      await _plugin.zonedSchedule(
        id: _scheduledId,
        title: l10n.reminderNotificationTitle,
        body: l10n.reminderNotificationBodyGeneric,
        scheduledDate: moment,
        notificationDetails: const NotificationDetails(
          iOS: DarwinNotificationDetails(),
          android: AndroidNotificationDetails(
            'daily_reminder',
            'Daily reminder',
            importance: Importance.defaultImportance,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e, st) {
      appLogger.handle(e, st, 'DailyReminder reschedule() error');
    }
  }
}

/// Replaces [dailyReminderServiceProvider] on phones.
final scheduledDailyReminderServiceProvider = Provider<DailyReminderService>((
  ref,
) {
  final service = ScheduledDailyReminderService(
    loadPreferences: () => ref.read(userPreferencesProvider).valueOrNull,
    loadStatus: () => ref.read(flashcardStatusProvider.future),
    onOpen: () => ref.read(dashboardSectionProvider.notifier).state =
        DashboardSection.flashcards,
    loadLocalizations: () => ref.read(appLocalizationsProvider),
  );
  ref.listen(userPreferencesProvider, (_, _) => service.reschedule());
  ref.onDispose(service.dispose);
  service.start();
  return service;
});
