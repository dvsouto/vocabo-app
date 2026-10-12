import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'package:vocabo_desktop/src/l10n/locale_providers.dart';
import 'package:vocabo_desktop/src/providers/api_client_provider.dart';
import 'package:vocabo_desktop/src/providers/dashboard_providers.dart';
import 'package:vocabo_desktop/src/providers/user_preferences_provider.dart';
import 'package:vocabo_desktop/src/services/daily_reminder_service.dart';

/// Lives while the dashboard is mounted, i.e. while the user is signed in.
final dailyReminderServiceProvider = Provider<DailyReminderService>((ref) {
  final service = DailyReminderService(
    loadPreferences: () => ref.read(userPreferencesProvider).valueOrNull,
    loadStatus: () => ref.read(apiClientProvider).flashcards.getStatus(),
    onOpen: () {
      ref.read(dashboardSectionProvider.notifier).state =
          DashboardSection.flashcards;
      windowManager.show();
      windowManager.focus();
    },
    loadLocalizations: () => ref.read(appLocalizationsProvider),
  );

  // Re-check as soon as the preferences load or change, not only on the
  // next periodic tick.
  ref.listen(userPreferencesProvider, (_, _) => service.check());
  ref.onDispose(service.dispose);
  service.start();

  return service;
});
