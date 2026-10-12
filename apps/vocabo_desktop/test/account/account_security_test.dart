import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabo_api/vocabo_api.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_desktop/src/l10n/l10n.dart';
import 'package:vocabo_desktop/src/providers/api_client_provider.dart';
import 'package:vocabo_desktop/src/screens/password_reset/password_reset_screen.dart';
import 'package:vocabo_desktop/src/widgets/account/delete_account_dialog.dart';
import 'package:vocabo_desktop/src/widgets/legal/legal_consent_text.dart';

final _socialUser = User(
  id: 'u1',
  name: 'Ana',
  email: 'ana@example.com',
  hasPassword: false,
  providers: const ['google'],
  createdAt: DateTime(2026),
);

Widget _host(Widget child) => ProviderScope(
  overrides: [
    apiClientProvider.overrideWith(
      (ref) => throw StateError('API must not be used'),
    ),
  ],
  child: MaterialApp(
    theme: VocaboTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  ),
);

void main() {
  testWidgets('password reset validates the email before calling the API', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(const PasswordResetScreen()));

    await tester.enterText(find.byType(TextField), 'not-an-email');
    await tester.tap(find.text('Send code'));
    await tester.pump();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
  });

  testWidgets('social accounts confirm the deletion by typing DELETE', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showDeleteAccountDialog(context, _socialUser),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    FilledButton deleteButton() =>
        tester.widget<FilledButton>(find.byType(FilledButton));

    expect(find.text('TYPE DELETE TO CONFIRM'), findsOneWidget);
    expect(deleteButton().onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'delete');
    await tester.pump();

    expect(deleteButton().onPressed, isNotNull);
  });

  testWidgets('the consent text opens the privacy policy', (tester) async {
    await tester.pumpWidget(
      _host(
        const Scaffold(
          body: Center(
            child: LegalConsentText(action: LegalConsentAction.continuing),
          ),
        ),
      ),
    );

    final text = find.byType(RichText).first;
    final paragraph = tester.renderObject<RenderParagraph>(text);
    final fullText = paragraph.text.toPlainText();
    final offset = fullText.indexOf('Privacy Policy') + 3;
    final box = paragraph
        .getBoxesForSelection(
          TextSelection(baseOffset: offset, extentOffset: offset + 1),
        )
        .first;
    await tester.tapAt(
      tester.getTopLeft(text) + Offset(box.left + 1, box.top + 1),
    );
    await tester.pumpAndSettle();

    expect(find.text('Privacy Policy'), findsWidgets);
    expect(find.text('1. Data we collect'), findsOneWidget);
  });
}
