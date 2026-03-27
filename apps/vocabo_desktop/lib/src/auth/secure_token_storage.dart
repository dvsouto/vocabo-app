import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vocabo_api/vocabo_api.dart';

class SecureTokenStorage implements TokenStorage {
  static const _tokenKey = 'vocabo_auth_token';

  final FlutterSecureStorage _storage;

  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              mOptions: MacOsOptions(
                accessibility: KeychainAccessibility.first_unlock,
                useDataProtectionKeyChain: true,
              ),
            );

  @override
  Future<String?> getToken() => _storage.read(key: _tokenKey);

  @override
  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  @override
  Future<void> deleteToken() => _storage.delete(key: _tokenKey);
}
