import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:vocabo_core/vocabo_core.dart';

import 'translation_result.dart';
import 'translation_service.dart';

class MlKitTranslationService implements TranslationService {
  OnDeviceTranslator? _translator;
  TranslateLanguage? _cachedSource;
  TranslateLanguage? _cachedTarget;
  final _modelManager = OnDeviceTranslatorModelManager();

  @override
  Future<TranslationResult> translate({
    required String text,
    required TranslationLanguage sourceLanguage,
    required TranslationLanguage targetLanguage,
  }) async {
    final source = _mapLanguage(sourceLanguage);
    final target = _mapLanguage(targetLanguage);

    if (source == null || target == null) {
      throw TranslationLanguageNotSupportedException(
        'Language pair not supported: '
        '${sourceLanguage.displayName} → ${targetLanguage.displayName}',
      );
    }

    await _ensureModelsDownloaded(source, target);

    if (_translator == null ||
        _cachedSource != source ||
        _cachedTarget != target) {
      _translator?.close();
      _translator = OnDeviceTranslator(
        sourceLanguage: source,
        targetLanguage: target,
      );
      _cachedSource = source;
      _cachedTarget = target;
    }

    try {
      final translated = await _translator!.translateText(text);
      return TranslationResult(translatedText: translated);
    } catch (e) {
      throw TranslationException('Translation failed: $e');
    }
  }

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> isLanguagePairInstalled({
    required TranslationLanguage source,
    required TranslationLanguage target,
  }) async => true;

  @override
  Future<void> openTranslationSettings() async {}

  @override
  void dispose() {
    _translator?.close();
    _translator = null;
  }

  Future<void> _ensureModelsDownloaded(
    TranslateLanguage source,
    TranslateLanguage target,
  ) async {
    final sourceReady =
        await _modelManager.isModelDownloaded(source.bcpCode);
    if (!sourceReady) {
      await _modelManager.downloadModel(source.bcpCode);
    }

    final targetReady =
        await _modelManager.isModelDownloaded(target.bcpCode);
    if (!targetReady) {
      await _modelManager.downloadModel(target.bcpCode);
    }
  }

  TranslateLanguage? _mapLanguage(TranslationLanguage language) {
    return switch (language) {
      TranslationLanguage.english => TranslateLanguage.english,
      TranslationLanguage.portuguese => TranslateLanguage.portuguese,
      TranslationLanguage.spanish => TranslateLanguage.spanish,
      TranslationLanguage.french => TranslateLanguage.french,
      TranslationLanguage.german => TranslateLanguage.german,
      TranslationLanguage.italian => TranslateLanguage.italian,
      TranslationLanguage.japanese => TranslateLanguage.japanese,
      TranslationLanguage.korean => TranslateLanguage.korean,
    };
  }
}
