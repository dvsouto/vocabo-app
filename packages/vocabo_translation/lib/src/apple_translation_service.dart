import 'dart:async';

import 'package:flutter/services.dart';
import 'package:vocabo_core/vocabo_core.dart';

import 'translation_result.dart';
import 'translation_service.dart';

class AppleTranslationService implements TranslationService {
  static const _channel = MethodChannel('vocabo/translation');
  static const _timeout = Duration(seconds: 15);

  @override
  Future<TranslationResult> translate({
    required String text,
    required TranslationLanguage sourceLanguage,
    required TranslationLanguage targetLanguage,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'translate',
        {
          'text': text,
          'sourceLocale': sourceLanguage.localeCode,
          'targetLocale': targetLanguage.localeCode,
        },
      ).timeout(_timeout);

      if (result == null) {
        throw const TranslationException('No result from native translation');
      }

      return TranslationResult(
        translatedText: result['translatedText'] as String,
        pronunciation: result['pronunciation'] as String?,
      );
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'UNAVAILABLE':
          throw TranslationUnavailableException(
            e.message ?? 'Translation unavailable',
          );
        case 'LANGUAGE_NOT_SUPPORTED':
          throw TranslationLanguageNotSupportedException(
            e.message ?? 'Language pair not supported',
          );
        case 'LANGUAGES_NOT_INSTALLED':
          throw TranslationUnavailableException(
            e.message ?? 'Translation languages not installed',
          );
        default:
          throw TranslationException(
            e.message ?? 'Translation failed',
          );
      }
    } on TimeoutException {
      throw const TranslationException('Translation timed out');
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      final result = await _channel
          .invokeMethod<bool>('isAvailable')
          .timeout(_timeout);
      return result ?? false;
    } on PlatformException {
      return false;
    } on TimeoutException {
      return false;
    }
  }

  @override
  Future<bool> isLanguagePairInstalled({
    required TranslationLanguage source,
    required TranslationLanguage target,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'isLanguagePairInstalled',
        {
          'sourceLocale': source.localeCode,
          'targetLocale': target.localeCode,
        },
      ).timeout(_timeout);
      return result ?? false;
    } on PlatformException {
      return false;
    } on TimeoutException {
      return false;
    }
  }

  @override
  Future<void> openTranslationSettings() async {
    // Fire-and-forget: don't await because opening Settings causes the app
    // to lose focus, which may hide the tray panel and block the response.
    _channel.invokeMethod<void>('openTranslationSettings').ignore();
  }

  @override
  void dispose() {}
}
