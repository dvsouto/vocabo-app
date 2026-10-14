import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_api/vocabo_api.dart';
import 'package:vocabo_app/src/pro/plan_providers.dart';
import 'package:vocabo_app/src/auth/device_info.dart';
import 'package:vocabo_app/src/auth/secure_token_storage.dart';
import 'package:vocabo_app/src/config/env.dart';
import 'package:vocabo_app/src/l10n/locale_providers.dart';
import 'package:vocabo_app/src/providers/auth_providers.dart';

final Provider<VocaboApiClient> apiClientProvider = Provider<VocaboApiClient>((
  ref,
) {
  return VocaboApiClient(
    baseUrl: Env.apiUrl,
    tokenStorage: SecureTokenStorage(),
    device: ref.watch(deviceInfoProvider),
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
      ref.invalidate(authStatusProvider);
    },
  );
});
