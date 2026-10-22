import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';

import 'package:vocabo_app/src/data/local_store.dart';
import 'package:vocabo_app/src/providers/api_client_provider.dart';
import 'package:vocabo_app/src/sync/connectivity.dart';
import 'package:vocabo_app/src/sync/sync_engine.dart';

class UserPreferencesNotifier extends AsyncNotifier<UserPreferences> {
  @override
  Future<UserPreferences> build() async {
    final api = ref.watch(apiClientProvider);
    return api.user.getPreferences();
  }

  /// Applies the change right away and saves it; offline it waits in the
  /// outbox instead of being undone.
  Future<void> _update(
    UserPreferences optimistic,
    Map<String, dynamic> payload,
    Future<UserPreferences> Function() save,
  ) async {
    final previous = state.valueOrNull ?? const UserPreferences();
    state = AsyncData(optimistic);
    try {
      state = AsyncData(await save());
      ref.read(isOnlineProvider.notifier).reportOnline();
    } catch (e, st) {
      if (isConnectionError(e)) {
        ref.read(isOnlineProvider.notifier).reportOffline();
        await ref
            .read(localStoreProvider)
            .enqueue('preferences.update', payload);
        ref.read(syncEngineProvider.notifier).scheduleFlush();
        return;
      }
      appLogger.handle(e, st, 'UserPreferences update error');
      state = AsyncData(previous);
    }
  }

  UserPreferences get _current => state.valueOrNull ?? const UserPreferences();

  Future<void> setShowTranslations(bool value) => _update(
    _current.copyWith(showTranslations: value),
    {'show_translations': value},
    () => ref
        .read(apiClientProvider)
        .user
        .updatePreferences(showTranslations: value),
  );

  Future<void> setDailyReminder({bool? enabled, String? time}) => _update(
    _current.copyWith(dailyReminderEnabled: enabled, dailyReminderTime: time),
    {'daily_reminder_enabled': ?enabled, 'daily_reminder_time': ?time},
    () => ref
        .read(apiClientProvider)
        .user
        .updatePreferences(
          dailyReminderEnabled: enabled,
          dailyReminderTime: time,
        ),
  );

  Future<void> setVoiceGender(String voice) => _update(
    _current.copyWith(voiceGender: voice),
    {'voice_gender': voice},
    () =>
        ref.read(apiClientProvider).user.updatePreferences(voiceGender: voice),
  );

  Future<void> toggleShowTranslations() {
    final current = state.valueOrNull?.showTranslations ?? true;
    return setShowTranslations(!current);
  }
}

final userPreferencesProvider =
    AsyncNotifierProvider<UserPreferencesNotifier, UserPreferences>(
      UserPreferencesNotifier.new,
    );

final showTranslationsProvider = Provider<bool>((ref) {
  return ref.watch(userPreferencesProvider).valueOrNull?.showTranslations ??
      true;
});
