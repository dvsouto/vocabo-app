import 'package:test/test.dart';
import 'package:vocabo_core/vocabo_core.dart';

void main() {
  group('password rules', () {
    test('needs 6 characters, a letter and a number', () {
      expect(isValidPassword('pass01'), isTrue);
      expect(isValidPassword('pa01'), isFalse);
      expect(isValidPassword('password'), isFalse);
      expect(isValidPassword('123456'), isFalse);
    });

    test('reports each rule separately', () {
      expect(PasswordRequirement.letter.isMetBy('123'), isFalse);
      expect(PasswordRequirement.number.isMetBy('123'), isTrue);
    });
  });

  group('suggestNativeLanguage', () {
    test('skips English when another supported language is listed', () {
      expect(
        suggestNativeLanguage([
          (languageCode: 'en', countryCode: 'US'),
          (languageCode: 'pt', countryCode: 'BR'),
        ]),
        'pt',
      );
    });

    test('uses the region when only English is configured', () {
      expect(
        suggestNativeLanguage([(languageCode: 'en', countryCode: 'BR')]),
        'pt',
      );
      expect(
        suggestNativeLanguage([(languageCode: 'en', countryCode: 'MX')]),
        'es',
      );
    });

    test('never suggests English', () {
      expect(
        suggestNativeLanguage([(languageCode: 'en', countryCode: 'US')]),
        defaultNativeLanguage,
      );
      expect(suggestNativeLanguage([]), defaultNativeLanguage);
      expect(NativeLanguage.byCode('en'), isNull);
    });

    test('interface languages include English', () {
      expect(interfaceLanguages.first.code, 'en');
      expect(suggestInterfaceLanguage(['pt-BR', 'en']), 'pt');
      expect(suggestInterfaceLanguage(['nl']), 'en');
    });

    test('ignores unsupported languages', () {
      expect(
        suggestNativeLanguage([
          (languageCode: 'nl', countryCode: 'NL'),
          (languageCode: 'fr', countryCode: 'FR'),
        ]),
        'fr',
      );
    });
  });

  group('User', () {
    test('parses the account fields', () {
      final user = User.fromJson({
        'id': 'u1',
        'name': 'Ana',
        'email': 'ana@example.com',
        'phone_country': 'BR',
        'phone_number': '+5511987654321',
        'age': 30,
        'avatar_url': '/storage/avatars/u1/1.png',
        'native_language': 'pt',
        'plan': 'pro',
        'email_verified': false,
        'phone_verified': true,
        'verified': true,
        'has_password': false,
        'providers': ['google'],
        'created_at': '2026-10-11T05:33:34.651Z',
      });

      expect(user.plan, UserPlan.pro);
      expect(user.plan.label, 'PRO');
      expect(user.hasPhone, isTrue);
      expect(user.providers, ['google']);
      expect(user.hasPassword, isFalse);
    });

    test('defaults to free for unknown plans', () {
      expect(UserPlan.fromJson('enterprise'), UserPlan.free);
    });
  });

  test('countLabel picks the singular or plural noun', () {
    expect(countLabel(1, 'day'), '1 day');
    expect(countLabel(0, 'day'), '0 days');
    expect(countLabel(2, 'entry', plural: 'entries'), '2 entries');
  });

  test('TranslationLanguage.fromCode covers every native language', () {
    expect(TranslationLanguage.fromCode('pt'), TranslationLanguage.portuguese);
    expect(TranslationLanguage.fromCode('zh'), TranslationLanguage.chinese);
    expect(
      TranslationLanguage.fromCode('pt_BR'),
      TranslationLanguage.portuguese,
    );
    for (final language in nativeLanguages) {
      expect(TranslationLanguage.fromCode(language.code), isNotNull);
    }
  });
}
