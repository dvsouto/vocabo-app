import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_api/vocabo_api.dart';
import 'package:vocabo_desktop/src/auth/device_info.dart';
import 'package:vocabo_desktop/src/auth/secure_token_storage.dart';
import 'package:vocabo_desktop/src/config/env.dart';
import 'package:vocabo_desktop/src/providers/auth_providers.dart';

final Provider<VocaboApiClient> apiClientProvider = Provider<VocaboApiClient>((
  ref,
) {
  return VocaboApiClient(
    baseUrl: Env.apiUrl,
    tokenStorage: SecureTokenStorage(),
    device: ref.watch(deviceInfoProvider),
    onSessionEnded: (reason) {
      ref.read(sessionNoticeProvider.notifier).state = switch (reason) {
        'session_limit' =>
          'You were signed out because your account was used on more '
              'than $maxActiveSessions devices.',
        'session_revoked' => 'This session was ended. Sign in again.',
        _ => null,
      };
      ref.invalidate(authStatusProvider);
    },
  );
});
