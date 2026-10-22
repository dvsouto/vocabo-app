import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_translation/vocabo_translation.dart';

import 'package:vocabo_app/src/auth/device_info.dart';
import 'package:vocabo_app/src/l10n/locale_providers.dart';
import 'package:vocabo_app/src/providers/user_profile_provider.dart';
import 'package:vocabo_app/src/services/translation_preferences_service.dart';

// Service providers
final translationPreferencesServiceProvider =
    Provider<TranslationPreferencesService>(
      (ref) => TranslationPreferencesService(),
    );

/// The translator used where Apple's framework is missing (Android, iOS
/// before 26). The mobile app overrides it with ML Kit; desktop has none.
final translationFallbackProvider = Provider<TranslationService?>((_) => null);

final translationServiceProvider = Provider<TranslationService>((ref) {
  final service = TranslationServiceFactory.create(
    fallback: ref.watch(translationFallbackProvider),
  );
  ref.onDispose(() => service.dispose());
  return service;
});

// --- Native Language ---

/// The language English words are translated into: the user's native one,
/// or the system language while the profile is unavailable.
final nativeTranslationLanguageProvider = FutureProvider<TranslationLanguage>((
  ref,
) async {
  String code;
  try {
    code = (await ref.watch(userProfileProvider.future)).nativeLanguage;
  } catch (_) {
    code = systemNativeLanguage();
  }
  return TranslationLanguage.fromCode(code) ?? TranslationLanguage.english;
});

// --- Translation Availability ---

final translationAvailabilityProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(translationServiceProvider);

  final isAvailable = await service.isAvailable();
  if (!isAvailable) return false;

  final direction = await ref.watch(translationDirectionProvider.future);
  final sourceLang = TranslationLanguage.fromDisplayName(
    direction.sourceLanguage,
  );
  final targetLang = TranslationLanguage.fromDisplayName(
    direction.targetLanguage,
  );

  if (sourceLang == null || targetLang == null) return false;
  // Native English speakers read definitions instead of translations.
  if (sourceLang == targetLang) return false;

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
    required this.targetLanguage,
  });

  TranslationDirection swap() => TranslationDirection(
    sourceLanguage: targetLanguage,
    targetLanguage: sourceLanguage,
  );
}

class TranslationDirectionNotifier extends AsyncNotifier<TranslationDirection> {
  /// English to the native language, unless the user swapped that pair.
  @override
  Future<TranslationDirection> build() async {
    final native = await ref.watch(nativeTranslationLanguageProvider.future);
    final direction = TranslationDirection(targetLanguage: native.displayName);

    final prefs = ref.watch(translationPreferencesServiceProvider);
    final saved = await prefs.load();
    final swapped =
        saved?.sourceLanguage == direction.targetLanguage &&
        saved?.targetLanguage == direction.sourceLanguage;
    return swapped ? direction.swap() : direction;
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

final translationDirectionProvider =
    AsyncNotifierProvider<TranslationDirectionNotifier, TranslationDirection>(
      TranslationDirectionNotifier.new,
    );

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
      translatedText: translatedText != null
          ? translatedText()
          : this.translatedText,
      pronunciation: pronunciation != null
          ? pronunciation()
          : this.pronunciation,
      isTranslating: isTranslating ?? this.isTranslating,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      needsLanguageInstall: needsLanguageInstall ?? this.needsLanguageInstall,
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

    state = state.copyWith(isTranslating: true, errorMessage: () => null);

    try {
      final service = ref.read(translationServiceProvider);
      final direction = ref.read(translationDirectionProvider).valueOrNull;
      if (direction == null) {
        state = state.copyWith(isTranslating: false);
        return;
      }

      final sourceLang = TranslationLanguage.fromDisplayName(
        direction.sourceLanguage,
      );
      final targetLang = TranslationLanguage.fromDisplayName(
        direction.targetLanguage,
      );

      if (sourceLang == null || targetLang == null) {
        state = state.copyWith(
          isTranslating: false,
          errorMessage: () =>
              ref.read(appLocalizationsProvider).translateErrorUnsupportedPair,
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
      state = state.copyWith(isTranslating: false, needsLanguageInstall: true);
    } on AppException catch (e) {
      state = state.copyWith(
        isTranslating: false,
        errorMessage: () => e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isTranslating: false,
        errorMessage: () =>
            ref.read(appLocalizationsProvider).translateErrorFailed('$e'),
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
      TranslationNotifier.new,
    );
