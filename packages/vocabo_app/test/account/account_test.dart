import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabo_api/vocabo_api.dart';

import 'package:vocabo_app/vocabo_app.dart';
import 'package:vocabo_l10n/vocabo_l10n.dart';

class _CancelledSignIn implements SocialSignIn {
  int calls = 0;

  @override
  SocialAuthProvider get provider => SocialAuthProvider.google;

  @override
  String get label => 'Google';

  @override
  Future<SocialCredential?> signIn() async {
    calls++;
    return null;
  }
}

void main() {
  group('verificationErrorMessage', () {
    test('explains the API codes', () {
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(
        verificationErrorMessage(
          l10n,
          const UnprocessableException('x', code: 'invalid_code'),
        ),
        'That code is not right. Check it and try again.',
      );
      expect(
        verificationErrorMessage(
          l10n,
          const UnprocessableException('x', code: 'expired_code'),
        ),
        'This code has expired. Send a new one.',
      );
      expect(
        verificationErrorMessage(l10n, const NetworkException('offline')),
        'No connection. Check your internet and try again.',
      );
    });
  });

  test('cancelling a social sign in does not reach the API', () async {
    final signIn = _CancelledSignIn();
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWith(
          (ref) => throw StateError('API must not be used'),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(socialLoginProvider.notifier).signIn(signIn);

    expect(signIn.calls, 1);
    expect(container.read(socialLoginProvider).hasError, isFalse);
  });

  testWidgets('signup validates the fields before calling the API', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWith(
            (ref) => throw StateError('API must not be used'),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SignUpScreen(),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).at(2), 'password');
    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(find.text('Enter your name.'), findsOneWidget);
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(
      find.text('The password does not meet the rules below.'),
      findsOneWidget,
    );
  });
}
