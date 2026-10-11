import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

TextEditingValue _edit(TextInputFormatter formatter, String from, String to) {
  return formatter.formatEditUpdate(
    TextEditingValue(text: from),
    TextEditingValue(text: to),
  );
}

void main() {
  group('CodeDigitsFormatter', () {
    const formatter = CodeDigitsFormatter(6);

    test('keeps the digits of a pasted message', () {
      expect(_edit(formatter, '', 'Your code is 123-456').text, '123456');
    });

    test('caps the code length', () {
      expect(_edit(formatter, '', '12345678').text, '123456');
    });
  });

  group('PhoneNationalFormatter', () {
    const brazil = PhoneNationalFormatter('BR');

    test('formats while typing', () {
      expect(_edit(brazil, '', '11987654321').text, '(11) 98765-4321');
    });

    test('backspace over a separator removes the digit before it', () {
      expect(_edit(brazil, '(11) 9', '(11)9').text, '(11');
    });

    test('limits Brazilian numbers to 11 digits', () {
      expect(_edit(brazil, '', '119876543210').text, '(11) 98765-4321');
    });
  });

  testWidgets('VocaboCodeInput completes when all digits are entered', (
    tester,
  ) async {
    String? completed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VocaboCodeInput(onCompleted: (code) => completed = code),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '482913');
    await tester.pump();

    expect(completed, '482913');
    for (final digit in '482913'.split('')) {
      expect(find.text(digit), findsOneWidget);
    }
  });

  testWidgets('VocaboPhoneField shows the country calling code', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VocaboPhoneField(
            country: phoneCountryByIso('BR')!,
            onCountryChanged: (_) {},
            controller: TextEditingController(),
          ),
        ),
      ),
    );

    expect(find.text('+55'), findsOneWidget);
  });
}
