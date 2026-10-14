import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabo_core/vocabo_core.dart';

import 'package:vocabo_l10n/vocabo_l10n.dart';
import 'package:vocabo_app/src/services/daily_reminder_service.dart';

class _FakeNotifications implements FlutterLocalNotificationsPlugin {
  final shown = <({String? title, String? body})>[];

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async => true;

  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails,
    String? payload,
  }) async {
    shown.add((title: title, body: body));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemoryStore implements ReminderStateStore {
  DateTime? last;

  @override
  Future<DateTime?> readLastNotifiedOn() async => last;

  @override
  Future<void> writeLastNotifiedOn(DateTime moment) async => last = moment;
}

FlashcardStatusSummary _status(int due) => FlashcardStatusSummary(
  totalActive: 10,
  dueCount: due,
  completedCount: 0,
  archivedCount: 0,
  hasActiveSession: false,
);

void main() {
  late _FakeNotifications notifications;
  late _MemoryStore store;
  late UserPreferences preferences;
  late int dueCount;
  late int statusCalls;

  DailyReminderService buildService() => DailyReminderService(
    loadPreferences: () => preferences,
    loadStatus: () async {
      statusCalls += 1;
      return _status(dueCount);
    },
    onOpen: () {},
    loadLocalizations: () => lookupAppLocalizations(const Locale('en')),
    notifications: notifications,
    stateStore: store,
  );

  final afterReminder = DateTime(2026, 10, 10, 8, 30);

  setUp(() {
    notifications = _FakeNotifications();
    store = _MemoryStore();
    preferences = const UserPreferences(
      dailyReminderEnabled: true,
      dailyReminderTime: '08:00',
    );
    dueCount = 3;
    statusCalls = 0;
  });

  test('notifies once a day with the due count', () async {
    final service = buildService();

    await service.check(now: afterReminder);
    await service.check(now: afterReminder.add(const Duration(hours: 1)));

    expect(notifications.shown, hasLength(1));
    expect(notifications.shown.single.title, 'Your flashcards are ready');
    expect(
      notifications.shown.single.body,
      '3 words are waiting to be recalled.',
    );
  });

  test('stays quiet when nothing is due, for the rest of the day', () async {
    dueCount = 0;
    final service = buildService();

    await service.check(now: afterReminder);
    dueCount = 2;
    await service.check(now: afterReminder.add(const Duration(minutes: 5)));

    expect(notifications.shown, isEmpty);
    expect(statusCalls, 1);
  });

  test('does nothing before the time or when disabled', () async {
    final service = buildService();

    await service.check(now: DateTime(2026, 10, 10, 7, 59));
    preferences = preferences.copyWith(dailyReminderEnabled: false);
    await service.check(now: afterReminder);

    expect(notifications.shown, isEmpty);
    expect(statusCalls, 0);
  });

  test('fires again the next day', () async {
    final service = buildService();

    await service.check(now: afterReminder);
    await service.check(now: afterReminder.add(const Duration(days: 1)));

    expect(notifications.shown, hasLength(2));
  });

  test('uses the singular when one word is due', () async {
    dueCount = 1;
    await buildService().check(now: afterReminder);

    expect(
      notifications.shown.single.body,
      '1 word is waiting to be recalled.',
    );
  });
}
