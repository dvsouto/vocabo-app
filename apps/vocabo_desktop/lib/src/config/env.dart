abstract final class Env {
  static const apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3080',
  );

  /// OAuth client id (iOS type) from Google Cloud. Empty until configured.
  static const googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');

  /// Resolves paths the API returns, such as avatar URLs, to absolute URLs.
  static String? resolveUrl(String? path) =>
      path == null ? null : Uri.parse(apiUrl).resolve(path).toString();
}
