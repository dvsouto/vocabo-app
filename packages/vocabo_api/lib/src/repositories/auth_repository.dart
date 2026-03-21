import 'package:vocabo_api/src/auth/token_storage.dart';
import 'package:vocabo_api/src/client/api_call.dart';
import 'package:vocabo_api/src/data_sources/auth_data_source.dart';

class AuthRepository {
  final AuthDataSource _dataSource;
  final TokenStorage _tokenStorage;

  AuthRepository({
    required AuthDataSource dataSource,
    required TokenStorage tokenStorage,
  })  : _dataSource = dataSource,
        _tokenStorage = tokenStorage;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final authToken = await apiCall(
      () => _dataSource.login(email: email, password: password),
    );

    await _tokenStorage.saveToken(authToken.token);
  }

  Future<void> logout() async {
    // TODO: call backend logout endpoint when available
    await _tokenStorage.deleteToken();
  }

  Future<bool> isAuthenticated() async {
    final token = await _tokenStorage.getToken();
    return token != null;
  }
}
