import 'package:test/test.dart';
import 'package:vocabo_api/vocabo_api.dart';

void main() {
  late VocaboApiClient apiClient;

  setUp(() {
    apiClient = VocaboApiClient(
      baseUrl: 'http://localhost:3080',
      tokenStorage: InMemoryTokenStorage(),
    );
  });

  group('Auth Login Integration', () {
    test('login with valid credentials succeeds', () async {
      await apiClient.auth.login(
        email: 'admin@admin.com',
        password: 'pass01',
      );

      final isAuthenticated = await apiClient.auth.isAuthenticated();
      expect(isAuthenticated, isTrue);
    });

    test('login with invalid credentials throws UnauthorizedException',
        () async {
      expect(
        () => apiClient.auth.login(
          email: 'admin@admin.com',
          password: 'wrong_password',
        ),
        throwsA(isA<UnauthorizedException>()),
      );

      final isAuthenticated = await apiClient.auth.isAuthenticated();
      expect(isAuthenticated, isFalse);
    });
  });
}
