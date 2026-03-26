import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_desktop/src/providers/api_client_provider.dart';
import 'package:vocabo_desktop/src/providers/user_vocabulary_providers.dart';

final showAddWordModalProvider = StateProvider<bool>((ref) => false);
final addWordInitialTermProvider = StateProvider<String>((ref) => '');

class AddWordState {
  final String term;
  final String language;
  final String? meaning;
  final String? translation;
  final WordType? wordType;
  final String? pronunciation;
  final String? ttsPronunciation;
  final String? exampleSentence;
  final bool autoDetect;
  final bool isSearching;
  final bool isValid;
  final String? backendHash;
  final Vocabulary? backendResult;
  final String? errorMessage;
  final bool isSaving;

  const AddWordState({
    this.term = '',
    this.language = 'English',
    this.meaning,
    this.translation,
    this.wordType,
    this.pronunciation,
    this.ttsPronunciation,
    this.exampleSentence,
    this.autoDetect = true,
    this.isSearching = false,
    this.isValid = false,
    this.backendHash,
    this.backendResult,
    this.errorMessage,
    this.isSaving = false,
  });

  bool get canSave {
    if (isSaving) return false;

    if (autoDetect) {
      return isValid && backendResult != null;
    }

    return term.trim().isNotEmpty &&
        ((meaning != null && meaning!.trim().isNotEmpty) ||
            (translation != null && translation!.trim().isNotEmpty));
  }

  AddWordState copyWith({
    String? term,
    String? language,
    String? Function()? meaning,
    String? Function()? translation,
    WordType? Function()? wordType,
    String? Function()? pronunciation,
    String? Function()? ttsPronunciation,
    String? Function()? exampleSentence,
    bool? autoDetect,
    bool? isSearching,
    bool? isValid,
    String? Function()? backendHash,
    Vocabulary? Function()? backendResult,
    String? Function()? errorMessage,
    bool? isSaving,
  }) {
    return AddWordState(
      term: term ?? this.term,
      language: language ?? this.language,
      meaning: meaning != null ? meaning() : this.meaning,
      translation: translation != null ? translation() : this.translation,
      wordType: wordType != null ? wordType() : this.wordType,
      pronunciation:
          pronunciation != null ? pronunciation() : this.pronunciation,
      ttsPronunciation: ttsPronunciation != null
          ? ttsPronunciation()
          : this.ttsPronunciation,
      exampleSentence:
          exampleSentence != null ? exampleSentence() : this.exampleSentence,
      autoDetect: autoDetect ?? this.autoDetect,
      isSearching: isSearching ?? this.isSearching,
      isValid: isValid ?? this.isValid,
      backendHash: backendHash != null ? backendHash() : this.backendHash,
      backendResult:
          backendResult != null ? backendResult() : this.backendResult,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class AddWordNotifier extends Notifier<AddWordState> {
  Timer? _debounceTimer;
  CancelToken? _cancelToken;

  @override
  AddWordState build() => const AddWordState();

  void setTerm(String value) {
    state = state.copyWith(term: value);

    if (state.autoDetect && value.trim().isNotEmpty) {
      _debounceSearch();
    }
  }

  void setLanguage(String value) {
    state = state.copyWith(language: value);
  }

  void setMeaning(String value) {
    _disableAutoDetectIfNeeded();
    state = state.copyWith(meaning: () => value);
  }

  void setTranslation(String value) {
    _disableAutoDetectIfNeeded();
    state = state.copyWith(translation: () => value);
  }

  void setWordType(WordType? value) {
    _disableAutoDetectIfNeeded();
    state = state.copyWith(wordType: () => value);
  }

  void setPronunciation(String value) {
    _disableAutoDetectIfNeeded();
    state = state.copyWith(pronunciation: () => value);
  }

  void setExampleSentence(String value) {
    _disableAutoDetectIfNeeded();
    state = state.copyWith(exampleSentence: () => value);
  }

  void toggleAutoDetect(bool value) {
    state = state.copyWith(autoDetect: value);

    if (value && state.term.trim().isNotEmpty) {
      _search();
    }
  }

  void _disableAutoDetectIfNeeded() {
    if (state.autoDetect) {
      state = state.copyWith(autoDetect: false);
    }
  }

  void _debounceSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), _search);
  }

  Future<void> _search() async {
    final term = state.term.trim();
    if (term.isEmpty) return;

    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    state = state.copyWith(
      isSearching: true,
      errorMessage: () => null,
    );

    try {
      final api = ref.read(apiClientProvider);
      final result = await api.vocabulary.search(
        sourceLang: state.language,
        targetLang: 'Portuguese',
        term: term,
        cancelToken: _cancelToken,
      );

      state = state.copyWith(
        isSearching: false,
        isValid: true,
        meaning: () => result.meaning,
        translation: () => result.translation,
        wordType: () => result.wordType,
        pronunciation: () => result.pronunciation,
        ttsPronunciation: () => result.ttsPronunciation,
        exampleSentence: () => _extractExampleSentence(result.usageExamples),
        backendHash: () => result.contentHash,
        backendResult: () => result,
        errorMessage: () => null,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;

      if (e.response?.statusCode == 422) {
        state = state.copyWith(
          isSearching: false,
          isValid: false,
          errorMessage: () => 'Not a valid word or phrase',
        );
        return;
      }

      state = state.copyWith(
        isSearching: false,
        isValid: false,
        errorMessage: () => 'Search failed. Please try again.',
      );
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        isValid: false,
        errorMessage: () => 'Search failed. Please try again.',
      );
    }
  }

  String? _extractExampleSentence(UsageExamples? examples) {
    if (examples == null) return null;
    final entries = examples.toJson().values;
    for (final value in entries) {
      if (value is List && value.isNotEmpty) {
        return value.first.toString();
      }
    }
    return null;
  }

  Future<bool> save() async {
    if (!state.canSave) return false;

    state = state.copyWith(isSaving: true);

    try {
      final usageExamples = _buildUsageExamples();

      final currentHash = computeVocabularyHash(
        term: state.term,
        language: state.language,
        translation: state.translation,
        meaning: state.meaning,
        wordType: state.wordType?.value,
        pronunciation: state.pronunciation,
        ttsPronunciation: state.ttsPronunciation,
        usageExamples: usageExamples,
      );

      final data = {
        'term': state.term,
        'language': state.language,
        'translation': state.translation,
        'meaning': state.meaning ?? '',
        'word_type': state.wordType?.value ?? 'noun',
        'pronunciation': state.pronunciation ?? '',
        'tts_pronunciation': state.ttsPronunciation ?? '',
        'usage_examples': usageExamples,
        'content_hash': state.autoDetect
            ? (state.backendHash ?? currentHash)
            : currentHash,
      };

      debugPrint('[AddWord] save() - sending data: $data');
      debugPrint('[AddWord] save() - autoDetect: ${state.autoDetect}, backendHash: ${state.backendHash}, currentHash: $currentHash');

      await ref
          .read(userVocabularyListProvider.notifier)
          .addVocabulary(data);

      state = state.copyWith(isSaving: false);
      return true;
    } catch (e, st) {
      debugPrint('[AddWord] save() - ERROR: $e');
      debugPrint('[AddWord] save() - Stack: $st');
      if (e is DioException) {
        debugPrint('[AddWord] save() - DioException status: ${e.response?.statusCode}');
        debugPrint('[AddWord] save() - DioException body: ${e.response?.data}');
      }
      state = state.copyWith(
        isSaving: false,
        errorMessage: () => e is DioException && e.response?.statusCode == 409
            ? 'This word is already in your vocabulary'
            : 'Failed to save. Please try again.',
      );
      return false;
    }
  }

  dynamic _buildUsageExamples() {
    if (state.backendResult?.usageExamples != null && state.autoDetect) {
      return state.backendResult!.usageExamples!.toJson();
    }

    if (state.exampleSentence != null &&
        state.exampleSentence!.trim().isNotEmpty) {
      return [state.exampleSentence!.trim()];
    }

    return <String>[];
  }

  void reset() {
    _debounceTimer?.cancel();
    _cancelToken?.cancel();
    state = const AddWordState();
  }

  void initFromTerm(String term) {
    state = const AddWordState().copyWith(term: term);
    if (term.trim().isNotEmpty) {
      _search();
    }
  }
}

final addWordNotifierProvider =
    NotifierProvider<AddWordNotifier, AddWordState>(AddWordNotifier.new);
