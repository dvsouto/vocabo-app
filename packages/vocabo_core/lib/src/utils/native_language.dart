/// A native language offered at signup. Mirrors the API list. English is
/// not one: it is the language being learned.
class NativeLanguage {
  const NativeLanguage(this.code, this.englishName, this.nativeName);

  /// ISO 639-1 code.
  final String code;
  final String englishName;

  /// Name written in the language itself, e.g. `Português`.
  final String nativeName;

  String get displayName =>
      englishName == nativeName ? englishName : '$nativeName · $englishName';

  static NativeLanguage? byCode(String code) {
    for (final language in nativeLanguages) {
      if (language.code == code) return language;
    }
    return null;
  }
}

/// Focused on the largest groups of people learning English.
const nativeLanguages = [
  NativeLanguage('pt', 'Portuguese', 'Português'),
  NativeLanguage('es', 'Spanish', 'Español'),
  NativeLanguage('fr', 'French', 'Français'),
  NativeLanguage('de', 'German', 'Deutsch'),
  NativeLanguage('it', 'Italian', 'Italiano'),
  NativeLanguage('ru', 'Russian', 'Русский'),
  NativeLanguage('tr', 'Turkish', 'Türkçe'),
  NativeLanguage('ar', 'Arabic', 'العربية'),
  NativeLanguage('hi', 'Hindi', 'हिन्दी'),
  NativeLanguage('zh', 'Chinese', '中文'),
  NativeLanguage('ja', 'Japanese', '日本語'),
  NativeLanguage('ko', 'Korean', '한국어'),
  NativeLanguage('vi', 'Vietnamese', 'Tiếng Việt'),
  NativeLanguage('id', 'Indonesian', 'Bahasa Indonesia'),
  NativeLanguage('pl', 'Polish', 'Polski'),
];

/// Used when the system gives no hint of a supported native language.
const defaultNativeLanguage = 'pt';

const _english = NativeLanguage('en', 'English', 'English');

/// Languages the app interface can be shown in: English plus every native
/// language.
const interfaceLanguages = [_english, ...nativeLanguages];

NativeLanguage? interfaceLanguageByCode(String code) {
  for (final language in interfaceLanguages) {
    if (language.code == code) return language;
  }
  return null;
}

/// The interface language matching the system's preferred languages, or
/// English.
String suggestInterfaceLanguage(List<String> preferredLanguageCodes) {
  for (final code in preferredLanguageCodes) {
    final language = code.split(RegExp('[-_]')).first.toLowerCase();
    if (interfaceLanguageByCode(language) != null) return language;
  }
  return 'en';
}

const _regionLanguages = {
  'BR': 'pt',
  'PT': 'pt',
  'AO': 'pt',
  'MZ': 'pt',
  'ES': 'es',
  'MX': 'es',
  'AR': 'es',
  'CO': 'es',
  'CL': 'es',
  'PE': 'es',
  'VE': 'es',
  'UY': 'es',
  'PY': 'es',
  'BO': 'es',
  'EC': 'es',
  'CR': 'es',
  'GT': 'es',
  'DO': 'es',
  'CU': 'es',
  'PA': 'es',
  'SV': 'es',
  'HN': 'es',
  'NI': 'es',
  'FR': 'fr',
  'DE': 'de',
  'AT': 'de',
  'IT': 'it',
  'RU': 'ru',
  'TR': 'tr',
  'SA': 'ar',
  'EG': 'ar',
  'AE': 'ar',
  'MA': 'ar',
  'DZ': 'ar',
  'IQ': 'ar',
  'JO': 'ar',
  'IN': 'hi',
  'CN': 'zh',
  'TW': 'zh',
  'HK': 'zh',
  'JP': 'ja',
  'KR': 'ko',
  'VN': 'vi',
  'ID': 'id',
  'PL': 'pl',
};

/// Guesses the native language from the system's preferred languages.
///
/// Many people keep the system in English while their native language comes
/// later in the list, so the first supported language wins. With only
/// English configured, the region of the locale decides (e.g. `en_BR`), then
/// [defaultNativeLanguage]. The user always confirms the choice.
String suggestNativeLanguage(
  List<({String languageCode, String? countryCode})> preferredLocales,
) {
  bool isSupported(String code) => NativeLanguage.byCode(code) != null;

  for (final locale in preferredLocales) {
    final code = locale.languageCode.toLowerCase();
    if (isSupported(code)) return code;
  }

  for (final locale in preferredLocales) {
    final region = _regionLanguages[locale.countryCode?.toUpperCase()];
    if (region != null) return region;
  }

  return defaultNativeLanguage;
}
