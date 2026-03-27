import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_desktop/src/providers/api_client_provider.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

final authStatusProvider = FutureProvider<AuthStatus>((ref) async {
  final api = ref.watch(apiClientProvider);
  final isAuth = await api.auth.isAuthenticated();
  return isAuth ? AuthStatus.authenticated : AuthStatus.unauthenticated;
});

final loginProvider =
    AsyncNotifierProvider<LoginNotifier, void>(LoginNotifier.new);

final logoutProvider =
    AsyncNotifierProvider<LogoutNotifier, void>(LogoutNotifier.new);

class LoginNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(apiClientProvider);
      await api.auth.login(email: email, password: password);
      ref.invalidate(authStatusProvider);
    });
  }
}

class LogoutNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> logout() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(apiClientProvider);
      await api.auth.logout();
      ref.invalidate(authStatusProvider);
    });
  }
}
