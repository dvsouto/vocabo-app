import 'package:test/test.dart';
import 'package:vocabo_core/vocabo_core.dart';

void main() {
  group('phoneCountries', () {
    test('names every supported region', () {
      expect(phoneCountries.length, greaterThan(240));
      expect(
        phoneCountries.map((c) => c.isoCode).toSet().length,
        phoneCountries.length,
      );
    });

    test('carries calling code and flag', () {
      final brazil = phoneCountryByIso('br')!;
      expect(brazil.name, 'Brazil');
      expect(brazil.dialCode, '55');
      expect(brazil.flag, '🇧🇷');
    });

    test('searches by name, iso code and calling code', () {
      final brazil = phoneCountryByIso('BR')!;
      expect(brazil.matches('bra'), isTrue);
      expect(brazil.matches('br'), isTrue);
      expect(brazil.matches('+55'), isTrue);
      expect(brazil.matches('spain'), isFalse);
    });
  });

  group('formatPhoneNational', () {
    test('formats Brazilian numbers with the area code as the user types', () {
      expect(formatPhoneNational('BR', '1'), '(1');
      expect(formatPhoneNational('BR', '11'), '(11');
      expect(formatPhoneNational('BR', '119'), '(11) 9');
      expect(formatPhoneNational('BR', '119876'), '(11) 9876');
      expect(formatPhoneNational('BR', '1198765'), '(11) 9876-5');
      expect(formatPhoneNational('BR', '1132345678'), '(11) 3234-5678');
      expect(formatPhoneNational('BR', '11987654321'), '(11) 98765-4321');
    });

    test('uses the country pattern elsewhere', () {
      expect(formatPhoneNational('US', '4155550123'), '(415) 555-0123');
      expect(formatPhoneNational('ES', '612345678'), '612 34 56 78');
    });
  });

  group('validation and E.164', () {
    test('accepts mobile numbers only', () {
      expect(isValidPhone('BR', '(11) 98765-4321'), isTrue);
      expect(isValidPhone('BR', '1198765'), isFalse);
      expect(toE164('BR', '(11) 98765-4321'), '+5511987654321');
      expect(toE164('BR', '1198765'), isNull);
    });

    test('drops the national trunk prefix', () {
      expect(toE164('GB', '07400 123456'), '+447400123456');
    });

    test('round trips for display', () {
      expect(parseE164('+5511987654321'), (
        isoCode: 'BR',
        nationalNumber: '11987654321',
      ));
      expect(formatPhoneInternational('+5511987654321'), '+55 (11) 98765-4321');
      expect(
        formatPhoneInternational('+14155550123', isoHint: 'US'),
        '+1 (415) 555-0123',
      );
    });
  });
}
