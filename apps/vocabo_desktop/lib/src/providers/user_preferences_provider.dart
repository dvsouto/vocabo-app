import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_desktop/src/providers/api_client_provider.dart';

class UserPreferencesNotifier extends AsyncNotifier<UserPreferences> {
  @override
  Future<UserPreferences> build() async {
    final api = ref.watch(apiClientProvider);
    return api.user.getPreferences();
  }

  Future<void> setShowTranslations(bool value) async {
    final previous = state.valueOrNull ?? const UserPreferences();
    state = AsyncData(previous.copyWith(showTranslations: value));

    try {
      final api = ref.read(apiClientProvider);
      final saved = await api.user.updatePreferences(showTranslations: value);
      state = AsyncData(saved);
    } catch (e, st) {
      appLogger.handle(e, st, 'UserPreferences setShowTranslations() error');
      state = AsyncData(previous);
    }
  }

  Future<void> setDailyReminder({bool? enabled, String? time}) async {
    final previous = state.valueOrNull ?? const UserPreferences();
    state = AsyncData(
      previous.copyWith(dailyReminderEnabled: enabled, dailyReminderTime: time),
    );

    try {
      final api = ref.read(apiClientProvider);
      final saved = await api.user.updatePreferences(
        dailyReminderEnabled: enabled,
        dailyReminderTime: time,
      );
      state = AsyncData(saved);
    } catch (e, st) {
      appLogger.handle(e, st, 'UserPreferences setDailyReminder() error');
      state = AsyncData(previous);
    }
  }

  Future<void> setVoiceGender(String voice) async {
    final previous = state.valueOrNull ?? const UserPreferences();
    state = AsyncData(previous.copyWith(voiceGender: voice));

    try {
      final api = ref.read(apiClientProvider);
      final saved = await api.user.updatePreferences(voiceGender: voice);
      state = AsyncData(saved);
    } catch (e, st) {
      appLogger.handle(e, st, 'UserPreferences setVoiceGender() error');
      state = AsyncData(previous);
    }
  }

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
