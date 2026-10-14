import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vocabo_app/src/l10n/locale_providers.dart';
import 'package:vocabo_app/src/providers/api_client_provider.dart';
import 'package:vocabo_app/src/platform/platform_adapter.dart';
import 'package:vocabo_app/src/providers/dashboard_providers.dart';
import 'package:vocabo_app/src/providers/user_preferences_provider.dart';
import 'package:vocabo_app/src/services/daily_reminder_service.dart';

/// Lives while the dashboard is mounted, i.e. while the user is signed in.
final dailyReminderServiceProvider = Provider<DailyReminderService>((ref) {
  final service = DailyReminderService(
    loadPreferences: () => ref.read(userPreferencesProvider).valueOrNull,
    loadStatus: () => ref.read(apiClientProvider).flashcards.getStatus(),
    onOpen: () {
      ref.read(dashboardSectionProvider.notifier).state =
          DashboardSection.flashcards;
      ref.read(platformAdapterProvider).bringToFront();
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
