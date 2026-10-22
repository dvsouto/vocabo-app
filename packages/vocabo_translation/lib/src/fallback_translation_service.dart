import 'package:vocabo_core/vocabo_core.dart';

import 'translation_result.dart';
import 'translation_service.dart';

/// Uses [primary] when the device supports it and [fallback] otherwise.
/// iOS only offers Apple's headless translation from iOS 26, so older
/// phones translate with ML Kit.
class FallbackTranslationService implements TranslationService {
  FallbackTranslationService({required this.primary, required this.fallback});

  final TranslationService primary;
  final TranslationService fallback;
  Future<TranslationService>? _active;

  Future<TranslationService> _service() => _active ??= () async {
    try {
      if (await primary.isAvailable()) return primary;
    } catch (_) {}
    return fallback;
  }();

  @override
  Future<TranslationResult> translate({
    required String text,
    required TranslationLanguage sourceLanguage,
    required TranslationLanguage targetLanguage,
  }) async => (await _service()).translate(
    text: text,
    sourceLanguage: sourceLanguage,
    targetLanguage: targetLanguage,
  );

  @override
  Future<bool> isAvailable() async => (await _service()).isAvailable();

  @override
  Future<bool> isLanguagePairInstalled({
    required TranslationLanguage source,
    required TranslationLanguage target,
  }) async => (await _service()).isLanguagePairInstalled(
    source: source,
    target: target,
  );

  @override
  Future<void> openTranslationSettings() async =>
      (await _service()).openTranslationSettings();

  @override
  void dispose() {
    primary.dispose();
    fallback.dispose();
  }
}
