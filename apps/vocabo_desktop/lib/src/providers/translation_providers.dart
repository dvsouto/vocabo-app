import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_desktop/src/services/translation_preferences_service.dart';

// Service provider
final translationPreferencesServiceProvider =
    Provider<TranslationPreferencesService>(
        (ref) => TranslationPreferencesService());

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

  const TranslationState({
    this.inputText = '',
    this.translatedText,
    this.pronunciation,
    this.isTranslating = false,
    this.errorMessage,
  });

  bool get hasTranslation =>
      translatedText != null && translatedText!.isNotEmpty;

  TranslationState copyWith({
    String? inputText,
    String? Function()? translatedText,
    String? Function()? pronunciation,
    bool? isTranslating,
    String? Function()? errorMessage,
  }) {
    return TranslationState(
      inputText: inputText ?? this.inputText,
      translatedText:
          translatedText != null ? translatedText() : this.translatedText,
      pronunciation:
          pronunciation != null ? pronunciation() : this.pronunciation,
      isTranslating: isTranslating ?? this.isTranslating,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
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

    // TODO: Replace with actual API call when translation endpoint exists
    await Future.delayed(const Duration(milliseconds: 300));

    state = state.copyWith(
      isTranslating: false,
      translatedText: () => null,
      pronunciation: () => null,
    );
  }

  void clear() {
    _debounceTimer?.cancel();
    state = const TranslationState();
  }
}

final translationNotifierProvider =
    NotifierProvider<TranslationNotifier, TranslationState>(
        TranslationNotifier.new);
