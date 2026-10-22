import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_api/vocabo_api.dart';
import 'package:vocabo_app/src/pro/plan_providers.dart';
import 'package:vocabo_app/src/auth/device_info.dart';
import 'package:vocabo_app/src/auth/secure_token_storage.dart';
import 'package:vocabo_app/src/config/env.dart';
import 'package:vocabo_app/src/l10n/locale_providers.dart';
import 'package:vocabo_app/src/providers/auth_providers.dart';
import 'package:vocabo_app/src/services/local_data_service.dart';
import 'package:vocabo_app/src/data/local_store.dart';
import 'package:vocabo_app/src/sync/connectivity.dart';

final Provider<VocaboApiClient> apiClientProvider = Provider<VocaboApiClient>((
  ref,
) {
  return VocaboApiClient(
    baseUrl: Env.apiUrl,
    tokenStorage: SecureTokenStorage(),
    device: ref.watch(deviceInfoProvider),
    responseCache: ref.watch(localStoreProvider),
    isOffline: () => !ref.read(isOnlineProvider),
    onSessionEnded: (reason) {
      final l10n = ref.read(appLocalizationsProvider);
      ref.read(sessionNoticeProvider.notifier).state = switch (reason) {
        'session_limit' => l10n.authSessionLimitNotice(
          ref.read(planStatusProvider).valueOrNull?.limits.devices ??
              maxActiveSessions,
        ),
        'session_revoked' => l10n.authSessionRevokedNotice,
        _ => null,
      };
      // Signed out elsewhere: nothing of the account stays on this device.
      ref.read(localDataServiceProvider).clearAccountData();
      ref.invalidate(authStatusProvider);
    },
  );
});
