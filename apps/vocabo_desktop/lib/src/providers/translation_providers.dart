import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_translation/vocabo_translation.dart';

import 'package:vocabo_desktop/src/services/translation_preferences_service.dart';

// Service providers
final translationPreferencesServiceProvider =
    Provider<TranslationPreferencesService>(
        (ref) => TranslationPreferencesService());

final translationServiceProvider = Provider<TranslationService>((ref) {
  final service = TranslationServiceFactory.create();
  ref.onDispose(() => service.dispose());
  return service;
});

// --- Translation Availability ---

final translationAvailabilityProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(translationServiceProvider);

  final isAvailable = await service.isAvailable();
  if (!isAvailable) return false;

  final direction = await ref.watch(translationDirectionProvider.future);
  final sourceLang =
      TranslationLanguage.fromDisplayName(direction.sourceLanguage);
  final targetLang =
      TranslationLanguage.fromDisplayName(direction.targetLanguage);

  if (sourceLang == null || targetLang == null) return false;

  return service.isLanguagePairInstalled(
    source: sourceLang,
    target: targetLang,
  );
});

// --- Translation Direction ---

class TranslationDirection {
  final String sourceLanguage;
  final String targetLanguage;

  const TranslationDirection({
    this.sourceLanguage = 'English',
    this.targetLanguage = 'Portuguese',
  });

  TranslationDirection swap() => TranslationDirection(
        sourceLanguage: targetLanguage,
        targetLanguage: sourceLanguage,
      );
}

class TranslationDirectionNotifier
    extends AsyncNotifier<TranslationDirection> {
  @override
  Future<TranslationDirection> build() async {
    final prefs = ref.watch(translationPreferencesServiceProvider);
    final saved = await prefs.load();
    if (saved != null) {
      return TranslationDirection(
        sourceLanguage: saved.sourceLanguage,
        targetLanguage: saved.targetLanguage,
      );
    }
    return const TranslationDirection();
  }

  Future<void> swapLanguages() async {
    final current = state.valueOrNull;
    if (current == null) return;

    final swapped = current.swap();
    state = AsyncData(swapped);

    final prefs = ref.read(translationPreferencesServiceProvider);
    await prefs.save(
      sourceLanguage: swapped.sourceLanguage,
      targetLanguage: swapped.targetLanguage,
    );
  }
}

final translationDirectionProvider = AsyncNotifierProvider<
    TranslationDirectionNotifier,
    TranslationDirection>(TranslationDirectionNotifier.new);

// --- Translation State ---

class TranslationState {
  final String inputText;
  final String? translatedText;
  final String? pronunciation;
  final bool isTranslating;
  final String? errorMessage;
  final bool needsLanguageInstall;

  const TranslationState({
    this.inputText = '',
    this.translatedText,
    this.pronunciation,
    this.isTranslating = false,
    this.errorMessage,
    this.needsLanguageInstall = false,
  });

  bool get hasTranslation =>
      translatedText != null && translatedText!.isNotEmpty;

  TranslationState copyWith({
    String? inputText,
    String? Function()? translatedText,
    String? Function()? pronunciation,
    bool? isTranslating,
    String? Function()? errorMessage,
    bool? needsLanguageInstall,
  }) {
    return TranslationState(
      inputText: inputText ?? this.inputText,
      translatedText:
          translatedText != null ? translatedText() : this.translatedText,
      pronunciation:
          pronunciation != null ? pronunciation() : this.pronunciation,
      isTranslating: isTranslating ?? this.isTranslating,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      needsLanguageInstall:
          needsLanguageInstall ?? this.needsLanguageInstall,
    );
  }
}

class TranslationNotifier extends Notifier<TranslationState> {
  Timer? _debounceTimer;

  @override
  TranslationState build() => const TranslationState();

  void setInputText(String value) {
    state = state.copyWith(inputText: value);

    if (value.trim().isNotEmpty) {
      _debounceTranslate();
    } else {
      state = state.copyWith(
        translatedText: () => null,
        pronunciation: () => null,
        isTranslating: false,
        errorMessage: () => null,
      );
    }
  }

  void onLanguagesSwapped({
    required String oldInputText,
    required String? oldTranslatedText,
  }) {
    _debounceTimer?.cancel();

    final newInput = oldTranslatedText ?? '';
    state = TranslationState(inputText: newInput);

    if (newInput.trim().isNotEmpty) {
      _debounceTranslate();
    }
  }

  void _debounceTranslate() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), _translate);
  }

  Future<void> _translate() async {
    final input = state.inputText.trim();
    if (input.isEmpty) return;

    state = state.copyWith(
      isTranslating: true,
      errorMessage: () => null,
    );

    try {
      final service = ref.read(translationServiceProvider);
      final direction = ref.read(translationDirectionProvider).valueOrNull;
      if (direction == null) {
        state = state.copyWith(isTranslating: false);
        return;
      }

      final sourceLang =
          TranslationLanguage.fromDisplayName(direction.sourceLanguage);
      final targetLang =
          TranslationLanguage.fromDisplayName(direction.targetLanguage);

      if (sourceLang == null || targetLang == null) {
        state = state.copyWith(
          isTranslating: false,
          errorMessage: () => 'Unsupported language pair',
        );
        return;
      }

      final result = await service.translate(
        text: input,
        sourceLanguage: sourceLang,
        targetLanguage: targetLang,
      );

      if (state.inputText.trim() != input) return;

      state = state.copyWith(
        isTranslating: false,
        translatedText: () => result.translatedText,
        pronunciation: () => result.pronunciation,
      );
    } on TranslationUnavailableException {
      state = state.copyWith(
        isTranslating: false,
        needsLanguageInstall: true,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        isTranslating: false,
        errorMessage: () => e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isTranslating: false,
        errorMessage: () => 'Translation failed: $e',
      );
    }
  }

  void clear() {
    _debounceTimer?.cancel();
    state = const TranslationState();
  }
}

final translationNotifierProvider =
    NotifierProvider<TranslationNotifier, TranslationState>(
        TranslationNotifier.new);
