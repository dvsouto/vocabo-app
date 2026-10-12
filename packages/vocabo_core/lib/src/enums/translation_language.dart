enum TranslationLanguage {
  english('en', 'English'),
  portuguese('pt', 'Portuguese'),
  spanish('es', 'Spanish'),
  french('fr', 'French'),
  german('de', 'German'),
  italian('it', 'Italian'),
  russian('ru', 'Russian'),
  turkish('tr', 'Turkish'),
  arabic('ar', 'Arabic'),
  hindi('hi', 'Hindi'),
  chinese('zh-Hans', 'Chinese (Simplified)'),
  japanese('ja', 'Japanese'),
  korean('ko', 'Korean'),
  vietnamese('vi', 'Vietnamese'),
  indonesian('id', 'Indonesian'),
  polish('pl', 'Polish');

  const TranslationLanguage(this.localeCode, this.displayName);

  final String localeCode;
  final String displayName;

  static TranslationLanguage? fromDisplayName(String name) {
    for (final lang in values) {
      if (lang.displayName.toLowerCase() == name.toLowerCase()) return lang;
    }
    return null;
  }

  /// Matches a language code such as `pt` or `zh`, ignoring the script.
  static TranslationLanguage? fromCode(String code) {
    final language = code.split(RegExp('[-_]')).first.toLowerCase();
    for (final lang in values) {
      if (lang.localeCode.split('-').first == language) return lang;
    }
    return null;
  }
}
