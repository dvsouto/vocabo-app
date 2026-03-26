import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_api/vocabo_api.dart';
import 'package:vocabo_desktop/src/auth/secure_token_storage.dart';
import 'package:vocabo_desktop/src/config/env.dart';

final apiClientProvider = Provider<VocaboApiClient>((ref) {
  return VocaboApiClient(
    baseUrl: Env.apiUrl,
    tokenStorage: SecureTokenStorage(),
  );
});
