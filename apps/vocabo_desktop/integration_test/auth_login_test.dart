import 'package:flutter_test/flutter_test.dart';
import 'package:vocabo_api/vocabo_api.dart';

void main() {
  late VocaboApiClient apiClient;

  setUp(() {
    apiClient = VocaboApiClient(
      baseUrl: 'http://localhost:3000',
      tokenStorage: InMemoryTokenStorage(),
    );
  });

  group('Auth Login Integration', () {
    test('login with valid credentials succeeds', () async {
      await apiClient.auth.login(
        email: 'test@vocabo.app',
        password: '123456',
      );

      final isAuthenticated = await apiClient.auth.isAuthenticated();
      expect(isAuthenticated, isTrue);
    });

    test('login with invalid credentials throws UnauthorizedException',
        () async {
      expect(
        () => apiClient.auth.login(
          email: 'test@vocabo.app',
          password: 'wrong_password',
        ),
        throwsA(isA<UnauthorizedException>()),
      );

      final isAuthenticated = await apiClient.auth.isAuthenticated();
      expect(isAuthenticated, isFalse);
    });
  });
}
