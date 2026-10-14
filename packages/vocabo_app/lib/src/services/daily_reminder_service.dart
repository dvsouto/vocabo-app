import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vocabo_core/vocabo_core.dart';

import 'package:vocabo_l10n/vocabo_l10n.dart';

/// Remembers the last day the reminder fired so it shows once per day,
/// even across app restarts.
abstract interface class ReminderStateStore {
  Future<DateTime?> readLastNotifiedOn();
  Future<void> writeLastNotifiedOn(DateTime moment);
}

class FileReminderStateStore implements ReminderStateStore {
  static const _fileName = 'daily_reminder.json';

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    final folder = Directory('${dir.path}/vocabo');
    if (!folder.existsSync()) folder.createSync(recursive: true);
    return File('${folder.path}/$_fileName');
  }

  @override
  Future<DateTime?> readLastNotifiedOn() async {
    try {
      final file = await _file();
      if (!file.existsSync()) return null;
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return DateTime.tryParse(json['last_notified_on'] as String? ?? '');
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writeLastNotifiedOn(DateTime moment) async {
    final file = await _file();
    await file.writeAsString(
      jsonEncode({'last_notified_on': moment.toIso8601String()}),
    );
  }
}

/// Shows the daily "words are waiting" notification while the app runs. A
/// periodic check lets the notification carry the due count at the moment
/// it fires; on desktop the app lives in the menu bar, so it is enough.
class DailyReminderService {
  DailyReminderService({
    required this.loadPreferences,
    required this.loadStatus,
    required this.onOpen,
    required this.loadLocalizations,
    FlutterLocalNotificationsPlugin? notifications,
    ReminderStateStore? stateStore,
    this.checkInterval = const Duration(minutes: 1),
  }) : _notifications = notifications ?? FlutterLocalNotificationsPlugin(),
       _stateStore = stateStore ?? FileReminderStateStore();

  final UserPreferences? Function() loadPreferences;
  final Future<FlashcardStatusSummary> Function() loadStatus;

  /// Called when the user clicks the notification.
  final void Function() onOpen;

  /// Translations in the current interface language, read when the
  /// notification fires.
  final AppLocalizations Function() loadLocalizations;
  final Duration checkInterval;

  static const _notificationId = 1001;

  final FlutterLocalNotificationsPlugin _notifications;
  final ReminderStateStore _stateStore;
  Timer? _timer;
  bool _initialized = false;
  bool _checking = false;

  Future<void> start() async {
    await _initialize();
    _timer?.cancel();
    _timer = Timer.periodic(checkInterval, (_) => check());
    await check();
  }

  void dispose() => _timer?.cancel();

  /// Asks the system for permission. Returns false when the user declined.
  Future<bool> requestPermission() async {
    await _initialize();
    final granted = switch (Platform.operatingSystem) {
      'macos' =>
        await _notifications
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, sound: true),
      'ios' =>
        await _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, sound: true),
      'android' =>
        await _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission(),
      _ => false,
    };
    return granted ?? false;
  }

  Future<void> check({DateTime? now}) async {
    if (_checking) return;
    _checking = true;

    try {
      final preferences = loadPreferences();
      if (preferences == null) return;

      final moment = now ?? DateTime.now();
      final lastNotifiedOn = await _stateStore.readLastNotifiedOn();
      final shouldNotify = DailyReminderSchedule.shouldNotify(
        enabled: preferences.dailyReminderEnabled,
        time: preferences.dailyReminderTime,
        now: moment,
        lastNotifiedOn: lastNotifiedOn,
      );
      if (!shouldNotify) return;

      final status = await loadStatus();
      await _stateStore.writeLastNotifiedOn(moment);
      if (status.dueCount == 0) return;

      final l10n = loadLocalizations();
      await _initialize();
      await _notifications.show(
        id: _notificationId,
        title: l10n.reminderNotificationTitle,
        body: l10n.reminderNotificationBody(status.dueCount),
        notificationDetails: const NotificationDetails(
          macOS: DarwinNotificationDetails(),
          iOS: DarwinNotificationDetails(),
          android: AndroidNotificationDetails(
            'daily_reminder',
            'Daily reminder',
            importance: Importance.defaultImportance,
          ),
        ),
      );
    } catch (e, st) {
      appLogger.handle(e, st, 'DailyReminder check() error');
    } finally {
      _checking = false;
    }
  }

  Future<void> _initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _notifications.initialize(
      settings: const InitializationSettings(
        macOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (_) => onOpen(),
    );
  }
}
