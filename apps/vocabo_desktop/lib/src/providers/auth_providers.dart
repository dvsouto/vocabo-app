import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_api/vocabo_api.dart';
import 'package:vocabo_desktop/src/auth/device_info.dart';
import 'package:vocabo_desktop/src/auth/social_sign_in.dart';
import 'package:vocabo_desktop/src/providers/api_client_provider.dart';
import 'package:vocabo_desktop/src/providers/user_profile_provider.dart';

/// Mirrors the API limit; the oldest session is signed out beyond it.
const maxActiveSessions = 3;

enum AuthStatus { unknown, unauthenticated, needsVerification, authenticated }

final authStatusProvider = FutureProvider<AuthStatus>((ref) async {
  final api = ref.watch(apiClientProvider);
  if (!await api.auth.isAuthenticated()) return AuthStatus.unauthenticated;

  try {
    final profile = await api.user.getProfile();
    return profile.verified
        ? AuthStatus.authenticated
        : AuthStatus.needsVerification;
  } on UnauthorizedException {
    return AuthStatus.unauthenticated;
  } on AppException catch (e, st) {
    // Offline or API errors keep the user signed in, as before.
    appLogger.handle(e, st, 'Profile check failed');
    return AuthStatus.authenticated;
  }
});

/// Why the user was signed out, shown once on the login screen.
final sessionNoticeProvider = StateProvider<String?>((_) => null);

void _refreshAccount(Ref ref) {
  ref.invalidate(userProfileProvider);
  ref.invalidate(authStatusProvider);
}

final loginProvider = AsyncNotifierProvider<LoginNotifier, void>(
  LoginNotifier.new,
);

final signUpProvider = AsyncNotifierProvider<SignUpNotifier, void>(
  SignUpNotifier.new,
);

final socialLoginProvider = AsyncNotifierProvider<SocialLoginNotifier, void>(
  SocialLoginNotifier.new,
);

final logoutProvider = AsyncNotifierProvider<LogoutNotifier, void>(
  LogoutNotifier.new,
);

final deleteAccountProvider =
    AsyncNotifierProvider<DeleteAccountNotifier, void>(
      DeleteAccountNotifier.new,
    );

final passwordResetProvider =
    AsyncNotifierProvider<PasswordResetNotifier, void>(
      PasswordResetNotifier.new,
    );

class LoginNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(apiClientProvider);
      await api.auth.login(email: email, password: password);
      _refreshAccount(ref);
    });
  }
}

class SignUpNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Creates the account, signs it in and uploads the optional photo
  /// ([avatarPng], already resized). A failed photo upload doesn't undo
  /// the signup; it can be added later from the profile.
  Future<void> signUp(SignUpRequest request, {Uint8List? avatarPng}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(apiClientProvider);
      await api.auth.register(request);

      if (avatarPng != null) {
        try {
          await api.user.uploadAvatar(base64Encode(avatarPng));
        } catch (e, st) {
          appLogger.handle(e, st, 'Avatar upload after signup failed');
        }
      }

      _refreshAccount(ref);
    });
  }
}

class SocialLoginNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Signs in (or up) with Google or Apple. Cancelling leaves the state
  /// untouched.
  Future<void> signIn(SocialSignIn provider) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final credential = await provider.signIn();
      if (credential == null) return;

      final api = ref.read(apiClientProvider);
      await api.auth.socialLogin(
        provider: provider.provider,
        idToken: credential.idToken,
        name: credential.name,
        nativeLanguage: systemNativeLanguage(),
      );
      _refreshAccount(ref);
    });
  }
}

class PasswordResetNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Sets the new password with the emailed code and signs in.
  Future<void> reset({
    required String email,
    required String code,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(apiClientProvider);
      await api.auth.resetPassword(
        email: email,
        code: code,
        password: password,
      );
      _refreshAccount(ref);
    });
  }
}

class DeleteAccountNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Deletes the account for good and returns to the login screen.
  Future<void> delete({String? password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(apiClientProvider);
      await api.user.deleteAccount(password: password);
      await api.auth.clearSession();
      ref.read(sessionNoticeProvider.notifier).state =
          'Your account and all of its data were deleted.';
      _refreshAccount(ref);
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
      ref.read(sessionNoticeProvider.notifier).state = null;
      _refreshAccount(ref);
    });
  }
}
