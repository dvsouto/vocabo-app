enum TranslationLanguage {
  english('en', 'English'),
  portuguese('pt', 'Portuguese'),
  spanish('es', 'Spanish'),
  french('fr', 'French'),
  german('de', 'German'),
  italian('it', 'Italian'),
  japanese('ja', 'Japanese'),
  korean('ko', 'Korean');

  const TranslationLanguage(this.localeCode, this.displayName);

  final String localeCode;
  final String displayName;

  static TranslationLanguage? fromDisplayName(String name) {
    for (final lang in values) {
      if (lang.displayName.toLowerCase() == name.toLowerCase()) return lang;
    }
    return null;
  }
}
