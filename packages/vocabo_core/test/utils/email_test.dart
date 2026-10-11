import 'package:test/test.dart';
import 'package:vocabo_core/vocabo_core.dart';

void main() {
  group('isValidEmail', () {
    test('accepts common addresses', () {
      expect(isValidEmail('admin@admin.com'), isTrue);
      expect(isValidEmail('  alex.doe+tag@mail.co.uk '), isTrue);
    });

    test('rejects malformed addresses', () {
      for (final value in [
        '',
        'admin',
        'admin@',
        '@admin.com',
        'admin@admin',
        'a b@x.com',
        'admin@admin.c',
      ]) {
        expect(isValidEmail(value), isFalse, reason: value);
      }
    });
  });
}
