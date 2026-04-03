import 'package:vocabo_core/vocabo_core.dart';

import 'translation_result.dart';

abstract interface class TranslationService {
  /// Translate text from source to target language.
  Future<TranslationResult> translate({
    required String text,
    required TranslationLanguage sourceLanguage,
    required TranslationLanguage targetLanguage,
  });

  /// Check if the translation service is available on this platform/version.
  Future<bool> isAvailable();

  /// Check if a language pair is installed and ready for translation.
  Future<bool> isLanguagePairInstalled({
    required TranslationLanguage source,
    required TranslationLanguage target,
  });

  /// Open the system settings for downloading translation languages.
  Future<void> openTranslationSettings();

  /// Release any resources held by this service.
  void dispose();
}
