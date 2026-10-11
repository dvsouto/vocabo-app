import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:vocabo_api/vocabo_api.dart';
import 'package:vocabo_desktop/src/config/env.dart';

/// What a provider hands back after the user signs in.
class SocialCredential {
  const SocialCredential({required this.idToken, this.name});

  final String idToken;

  /// Only Apple sends the name, and only on the first sign in.
  final String? name;
}

class SocialSignInException implements Exception {
  const SocialSignInException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// A native sign in flow (Google, Apple) that produces an ID token for the
/// API. Returns null when the user cancels.
abstract interface class SocialSignIn {
  SocialAuthProvider get provider;
  String get label;
  Future<SocialCredential?> signIn();
}

class GoogleSocialSignIn implements SocialSignIn {
  GoogleSocialSignIn({String clientId = Env.googleClientId})
    : _clientId = clientId;

  final String _clientId;
  Future<void>? _initialization;

  @override
  SocialAuthProvider get provider => SocialAuthProvider.google;

  @override
  String get label => 'Google';

  @override
  Future<SocialCredential?> signIn() async {
    if (_clientId.isEmpty) {
      throw const SocialSignInException(
        'Sign in with Google is not set up yet.',
      );
    }

    try {
      _initialization ??= GoogleSignIn.instance.initialize(clientId: _clientId);
      await _initialization;

      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const SocialSignInException('Google did not return an ID token.');
      }
      return SocialCredential(idToken: idToken, name: account.displayName);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw SocialSignInException(
        'Could not sign in with Google${e.description == null ? '' : ': ${e.description}'}',
      );
    }
  }
}

class AppleSocialSignIn implements SocialSignIn {
  @override
  SocialAuthProvider get provider => SocialAuthProvider.apple;

  @override
  String get label => 'Apple';

  @override
  Future<SocialCredential?> signIn() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const SocialSignInException('Apple did not return an ID token.');
      }
      final name = [
        credential.givenName,
        credential.familyName,
      ].whereType<String>().where((part) => part.isNotEmpty).join(' ');
      return SocialCredential(
        idToken: idToken,
        name: name.isEmpty ? null : name,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      throw const SocialSignInException(
        'Sign in with Apple is not available in this build.',
      );
    } on PlatformException {
      throw const SocialSignInException(
        'Sign in with Apple is not available in this build.',
      );
    }
  }
}

final googleSignInProvider = Provider<SocialSignIn>(
  (_) => GoogleSocialSignIn(),
);

final appleSignInProvider = Provider<SocialSignIn>((_) => AppleSocialSignIn());
