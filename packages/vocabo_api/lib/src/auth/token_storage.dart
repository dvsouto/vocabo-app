abstract interface class TokenStorage {
  Future<String?> getToken();
  Future<void> saveToken(String token);
  Future<void> deleteToken();
}
