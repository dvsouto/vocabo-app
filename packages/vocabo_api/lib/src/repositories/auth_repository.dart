import 'package:vocabo_core/vocabo_core.dart';

import 'package:vocabo_api/src/auth/token_storage.dart';
import 'package:vocabo_api/src/client/api_call.dart';
import 'package:vocabo_api/src/data_sources/auth_data_source.dart';

class AuthRepository {
  final AuthDataSource _dataSource;
  final TokenStorage _tokenStorage;

  AuthRepository({
    required AuthDataSource dataSource,
    required TokenStorage tokenStorage,
  }) : _dataSource = dataSource,
       _tokenStorage = tokenStorage;

  Future<void> login({required String email, required String password}) async {
    final authToken = await apiCall(
      () => _dataSource.login(email: email, password: password),
    );

    await _tokenStorage.saveToken(authToken.token);
  }

  /// Creates the account and signs it in.
  Future<void> register(SignUpRequest request) async {
    final authToken = await apiCall(() => _dataSource.register(request));

    await _tokenStorage.saveToken(authToken.token);
  }

  Future<void> socialLogin({
    required SocialAuthProvider provider,
    required String idToken,
    String? name,
    String? nativeLanguage,
  }) async {
    final authToken = await apiCall(
      () => _dataSource.socialLogin(
        provider: provider,
        idToken: idToken,
        name: name,
        nativeLanguage: nativeLanguage,
      ),
    );

    await _tokenStorage.saveToken(authToken.token);
  }

  /// Ends the session on the server when reachable; the local token is
  /// always removed.
  Future<void> logout() async {
    try {
      await apiCall(_dataSource.logout);
    } catch (e, st) {
      appLogger.handle(e, st, 'Logout request failed');
    } finally {
      await _tokenStorage.deleteToken();
    }
  }

  Future<bool> isAuthenticated() async {
    final token = await _tokenStorage.getToken();
    return token != null;
  }

  Future<VerificationDispatch> sendVerification(VerificationChannel channel) =>
      apiCall(() => _dataSource.sendVerification(channel));

  Future<User> confirmVerification(String code) =>
      apiCall(() => _dataSource.confirmVerification(code));
}
