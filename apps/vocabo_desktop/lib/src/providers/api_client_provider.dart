import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_api/vocabo_api.dart';
import 'package:vocabo_desktop/src/auth/secure_token_storage.dart';

final apiClientProvider = Provider<VocaboApiClient>((ref) {
  return VocaboApiClient(
    baseUrl: 'http://localhost:3000',
    tokenStorage: SecureTokenStorage(),
  );
});
