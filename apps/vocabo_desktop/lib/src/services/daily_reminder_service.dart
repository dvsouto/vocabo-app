import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vocabo_core/vocabo_core.dart';

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

/// Shows the daily "words are waiting" notification. The app lives in the
/// menu bar, so a periodic check is enough and lets the notification carry
/// the due count at the moment it fires.
class DailyReminderService {
  DailyReminderService({
    required this.loadPreferences,
    required this.loadStatus,
    required this.onOpen,
    FlutterLocalNotificationsPlugin? notifications,
    ReminderStateStore? stateStore,
    this.checkInterval = const Duration(minutes: 1),
  }) : _notifications = notifications ?? FlutterLocalNotificationsPlugin(),
       _stateStore = stateStore ?? FileReminderStateStore();

  final UserPreferences? Function() loadPreferences;
  final Future<FlashcardStatusSummary> Function() loadStatus;

  /// Called when the user clicks the notification.
  final void Function() onOpen;
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

  /// Asks macOS for permission. Returns false when the user declined.
  Future<bool> requestPermission() async {
    await _initialize();
    final macOS = _notifications
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    final granted = await macOS?.requestPermissions(alert: true, sound: true);
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

      await _initialize();
      await _notifications.show(
        id: _notificationId,
        title: 'Your flashcards are ready',
        body: status.dueCount == 1
            ? '1 word is waiting to be recalled.'
            : '${status.dueCount} words are waiting to be recalled.',
        notificationDetails: const NotificationDetails(
          macOS: DarwinNotificationDetails(),
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
      ),
      onDidReceiveNotificationResponse: (_) => onOpen(),
    );
  }
}
