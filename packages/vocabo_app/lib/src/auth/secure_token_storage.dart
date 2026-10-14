import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vocabo_api/vocabo_api.dart';

/// Keeps the auth token in the Keychain (Apple) or Keystore (Android).
///
/// On macOS the data protection keychain requires a team-signed build with
/// the `keychain-access-groups` entitlement. Ad-hoc signed builds (local
/// runs and e2e) fall back to the legacy login keychain, and finally to
/// memory, so signing in never fails because of where the token is stored.
class SecureTokenStorage implements TokenStorage {
  static const _tokenKey = 'vocabo_auth_token';

  SecureTokenStorage({List<FlutterSecureStorage>? storages})
    : _storages =
          storages ??
          const [
            FlutterSecureStorage(
              mOptions: MacOsOptions(
                accessibility: KeychainAccessibility.first_unlock,
                useDataProtectionKeyChain: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            ),
            FlutterSecureStorage(
              mOptions: MacOsOptions(
                accessibility: KeychainAccessibility.first_unlock,
                useDataProtectionKeyChain: false,
              ),
            ),
          ];

  final List<FlutterSecureStorage> _storages;
  int _active = 0;
  String? _memoryToken;

  bool get _inMemory => _active >= _storages.length;

  Future<T?> _run<T>(
    Future<T> Function(FlutterSecureStorage storage) op,
  ) async {
    while (!_inMemory) {
      try {
        return await op(_storages[_active]);
      } on PlatformException catch (e) {
        appLogger.warning(
          'SecureTokenStorage: keychain #$_active unavailable (${e.code})',
        );
        _active++;
      }
    }
    return null;
  }

  @override
  Future<String?> getToken() async {
    if (_memoryToken != null) return _memoryToken;

    // Reads without the entitlement return null instead of failing, so a
    // token saved by the fallback keychain is looked up there as well.
    for (final storage in _storages.skip(_active)) {
      try {
        final token = await storage.read(key: _tokenKey);
        if (token != null) return _memoryToken = token;
      } on PlatformException catch (_) {}
    }
    return null;
  }

  @override
  Future<void> saveToken(String token) async {
    _memoryToken = token;
    await _run((s) => s.write(key: _tokenKey, value: token));
  }

  @override
  Future<void> deleteToken() async {
    _memoryToken = null;
    await _run((s) => s.delete(key: _tokenKey));
  }
}
