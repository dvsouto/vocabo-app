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

  /// Signs in and returns the devices this sign in signed out.
  Future<List<RevokedSession>> login({
    required String email,
    required String password,
  }) async {
    final authToken = await apiCall(
      () => _dataSource.login(email: email, password: password),
    );

    await _tokenStorage.saveToken(authToken.token);
    return authToken.revokedSessions;
  }

  /// Creates the account and signs it in.
  Future<List<RevokedSession>> register(SignUpRequest request) async {
    final authToken = await apiCall(() => _dataSource.register(request));

    await _tokenStorage.saveToken(authToken.token);
    return authToken.revokedSessions;
  }

  /// Signs in with Google or Apple. [created] tells when the account was
  /// just made, so the app can confirm the profile details.
  Future<({bool created, List<RevokedSession> revokedSessions})> socialLogin({
    required SocialAuthProvider provider,
    required String idToken,
    String? name,
    String? nativeLanguage,
    String? interfaceLanguage,
  }) async {
    final result = await apiCall(
      () => _dataSource.socialLogin(
        provider: provider,
        idToken: idToken,
        name: name,
        nativeLanguage: nativeLanguage,
        interfaceLanguage: interfaceLanguage,
      ),
    );

    await _tokenStorage.saveToken(result.token.token);
    return (
      created: result.created,
      revokedSessions: result.token.revokedSessions,
    );
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

  /// Forgets the local token without calling the API, for sessions that no
  /// longer exist on the server (e.g. after deleting the account).
  Future<void> clearSession() => _tokenStorage.deleteToken();

  Future<bool> isAuthenticated() async {
    final token = await _tokenStorage.getToken();
    return token != null;
  }

  Future<VerificationDispatch> sendVerification(VerificationChannel channel) =>
      apiCall(() => _dataSource.sendVerification(channel));

  /// Emails a code to reset the password. Unknown addresses get the same
  /// answer, so the caller cannot tell whether the account exists.
  Future<VerificationDispatch> requestPasswordReset(String email) =>
      apiCall(() => _dataSource.requestPasswordReset(email));

  /// Sets a new password with the emailed code and signs in. Every other
  /// device is signed out.
  Future<List<RevokedSession>> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    final authToken = await apiCall(
      () => _dataSource.resetPassword(
        email: email,
        code: code,
        password: password,
      ),
    );

    await _tokenStorage.saveToken(authToken.token);
    return authToken.revokedSessions;
  }

  Future<User> confirmVerification(String code) =>
      apiCall(() => _dataSource.confirmVerification(code));
}
