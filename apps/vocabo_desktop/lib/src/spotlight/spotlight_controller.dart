import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';

import 'package:vocabo_desktop/src/pro/plan_providers.dart';
import 'package:vocabo_desktop/src/l10n/l10n.dart';
import 'package:vocabo_desktop/src/l10n/locale_providers.dart';
import 'package:vocabo_desktop/src/providers/api_client_provider.dart';
import 'package:vocabo_desktop/src/providers/audio_player_providers.dart';
import 'package:vocabo_desktop/src/providers/dictionary_providers.dart';
import 'package:vocabo_desktop/src/providers/translation_providers.dart';
import 'package:vocabo_desktop/src/providers/user_vocabulary_providers.dart';
import 'package:vocabo_desktop/src/spotlight/spotlight_host.dart';
import 'package:vocabo_desktop/src/spotlight/spotlight_items.dart';

const _sourceLanguage = TranslationLanguage.english;

class SpotlightState {
  const SpotlightState({
    this.query = '',
    this.items = const [],
    this.selectedIndex = 0,
    this.lookups = const [],
    this.isLoadingLookups = false,
    this.quickTranslations = const {},
    this.resolvingKey,
    this.isSaving = false,
    this.notice,
  });

  final String query;
  final List<SpotlightItem> items;
  final int selectedIndex;
  final List<TranslationLookup> lookups;
  final bool isLoadingLookups;

  /// Free on-device translations keyed by lowercase term.
  final Map<String, String> quickTranslations;

  /// Item being fetched from the API (full translation).
  final String? resolvingKey;
  final bool isSaving;
  final String? notice;

  SpotlightItem? get selected =>
      items.isEmpty ? null : items[selectedIndex.clamp(0, items.length - 1)];

  SpotlightState copyWith({
    String? query,
    List<SpotlightItem>? items,
    int? selectedIndex,
    List<TranslationLookup>? lookups,
    bool? isLoadingLookups,
    Map<String, String>? quickTranslations,
    String? Function()? resolvingKey,
    bool? isSaving,
    String? Function()? notice,
  }) {
    return SpotlightState(
      query: query ?? this.query,
      items: items ?? this.items,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      lookups: lookups ?? this.lookups,
      isLoadingLookups: isLoadingLookups ?? this.isLoadingLookups,
      quickTranslations: quickTranslations ?? this.quickTranslations,
      resolvingKey: resolvingKey != null ? resolvingKey() : this.resolvingKey,
      isSaving: isSaving ?? this.isSaving,
      notice: notice != null ? notice() : this.notice,
    );
  }
}

class SpotlightController extends Notifier<SpotlightState> {
  Timer? _quickTranslateTimer;

  @override
  SpotlightState build() {
    ref.listen(cachedUserVocabularyProvider, (_, _) => _rebuildItems());
    ref.listen(dictionaryInitProvider, (_, _) => _rebuildItems());
    ref.onDispose(() => _quickTranslateTimer?.cancel());
    return const SpotlightState();
  }

  SpotlightHost get _host => ref.read(spotlightHostProvider);

  AppLocalizations get _l10n => ref.read(appLocalizationsProvider);

  /// Called every time the panel opens: starts clean and refreshes the
  /// synced history and the local library cache.
  Future<void> onShown() async {
    state = state.copyWith(
      query: '',
      selectedIndex: 0,
      notice: () => null,
      resolvingKey: () => null,
    );
    ref.invalidate(cachedUserVocabularyProvider);
    _rebuildItems();
    await refreshLookups();
  }

  Future<void> refreshLookups() async {
    state = state.copyWith(isLoadingLookups: true);
    try {
      final lookups = await ref.read(apiClientProvider).lookups.list(limit: 50);
      state = state.copyWith(lookups: lookups, isLoadingLookups: false);
    } catch (e, st) {
      appLogger.handle(e, st, 'Spotlight refreshLookups() error');
      state = state.copyWith(isLoadingLookups: false);
    }
    _rebuildItems();
  }

  void setQuery(String query) {
    state = state.copyWith(query: query, selectedIndex: 0, notice: () => null);
    _rebuildItems();
  }

  void moveSelection(int delta) {
    if (state.items.isEmpty) return;
    final next = (state.selectedIndex + delta).clamp(0, state.items.length - 1);
    state = state.copyWith(selectedIndex: next);
    _scheduleQuickTranslation();
  }

  void select(int index) {
    if (index < 0 || index >= state.items.length) return;
    state = state.copyWith(selectedIndex: index);
    _scheduleQuickTranslation();
  }

  /// Enter: a known word copies its translation and closes; an unknown one
  /// is translated in full and stays open so the user can read it.
  Future<void> primaryAction() async {
    final item = state.selected;
    if (item == null) return;

    if (!item.isResolved) {
      await _resolve(item);
      return;
    }

    final translation = item.translation;
    if (translation != null && translation.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: translation));
    }
    unawaited(_record(item.vocabulary!.id, item.vocabularyType));
    await _host.hide();
  }

  /// Cmd+Enter: saves the word to the library (it becomes a flashcard).
  Future<void> saveSelected() async {
    var item = state.selected;
    if (item == null || state.isSaving) return;
    if (item.isInLibrary) {
      state = state.copyWith(notice: () => _l10n.spotlightNoticeAlreadySaved);
      return;
    }

    if (!item.isResolved) {
      item = await _resolve(item);
      if (item == null) return;
    }

    final vocabulary = item.vocabulary!;
    state = state.copyWith(isSaving: true, notice: () => null);
    try {
      await ref
          .read(apiClientProvider)
          .userVocabulary
          .add(
            data: {
              'term': vocabulary.term,
              'language': vocabulary.language,
              'translation': vocabulary.translation,
              'meaning': vocabulary.meaning ?? '',
              'word_type': vocabulary.wordType.value,
              'pronunciation': vocabulary.pronunciation ?? '',
              'tts_pronunciation': vocabulary.ttsPronunciation ?? '',
              'usage_examples':
                  vocabulary.usageExamples?.toJson() ?? <String>[],
              'content_hash': vocabulary.contentHash,
            },
          );
      unawaited(_host.notifyVocabularyChanged());
      await _record(vocabulary.id, item.vocabularyType);
      state = state.copyWith(
        isSaving: false,
        notice: () => _l10n.spotlightNoticeSaved,
      );
    } on ConflictException {
      state = state.copyWith(
        isSaving: false,
        notice: () => _l10n.spotlightNoticeAlreadySaved,
      );
    } catch (e, st) {
      appLogger.handle(e, st, 'Spotlight saveSelected() error');
      state = state.copyWith(
        isSaving: false,
        notice: () => _planNotice(e) ?? _l10n.spotlightNoticeSaveFailed,
      );
    }
  }

  Future<void> playSelected() async {
    final vocabulary = state.selected?.vocabulary;
    final hash = vocabulary?.contentHash;
    if (vocabulary == null || hash == null) return;
    await ref
        .read(audioPlayerServiceProvider)
        .play(
          vocabularyId: vocabulary.id,
          type: state.selected!.vocabularyType,
          contentHash: hash,
        );
  }

  Future<void> openSelectedInApp() async {
    final item = state.selected;
    if (item == null) return;
    await _host.openWord(
      userVocabularyId: item.userVocabularyId,
      term: item.term,
    );
  }

  /// Cmd+Backspace: forgets a word from the synced history.
  Future<void> removeSelectedFromHistory() async {
    final lookup = state.selected?.lookup;
    if (lookup == null) return;

    final previous = state.lookups;
    state = state.copyWith(
      lookups: previous.where((l) => l.id != lookup.id).toList(),
    );
    _rebuildItems(keepSelection: true);

    try {
      await ref.read(apiClientProvider).lookups.delete(lookup.id);
    } catch (e, st) {
      appLogger.handle(e, st, 'Spotlight removeSelectedFromHistory() error');
      state = state.copyWith(lookups: previous);
      _rebuildItems(keepSelection: true);
    }
  }

  /// The free plan limit, phrased for the spotlight, which has no room for
  /// the upgrade offer: it points to the app instead.
  String? _planNotice(Object error) {
    final reason = upgradeReasonFor(error);
    if (reason == null) return null;
    return _l10n.proLimitUpgradeInApp(reason.headline(_l10n));
  }

  /// Escape: clears the query first, closes on the second press.
  Future<void> dismiss() async {
    if (state.query.isNotEmpty) {
      setQuery('');
      return;
    }
    await _host.hide();
  }

  Future<SpotlightItem?> _resolve(SpotlightItem item) async {
    if (state.resolvingKey != null) return null;
    state = state.copyWith(resolvingKey: () => item.key, notice: () => null);

    try {
      final vocabulary = await ref
          .read(apiClientProvider)
          .vocabulary
          .search(sourceLang: _sourceLanguage.displayName, term: item.term);
      final lookup = await _record(vocabulary.id, 'system');
      state = state.copyWith(resolvingKey: () => null);
      _rebuildItems();

      final index = state.items.indexWhere(
        (candidate) => candidate.vocabulary?.id == vocabulary.id,
      );
      if (index >= 0) {
        state = state.copyWith(selectedIndex: index);
        return state.items[index];
      }

      // The resolved term may not match the typed query (e.g. a typo that
      // the API corrected): show it on top anyway.
      final resolved = SpotlightItem(
        section: SpotlightSection.recent,
        term: vocabulary.term,
        vocabulary: vocabulary,
        lookup: lookup,
      );
      state = state.copyWith(
        items: [resolved, ...state.items],
        selectedIndex: 0,
      );
      return resolved;
    } on UnprocessableException {
      state = state.copyWith(
        resolvingKey: () => null,
        notice: () => _l10n.spotlightNoticeInvalidWord,
      );
    } catch (e, st) {
      appLogger.handle(e, st, 'Spotlight resolve() error');
      state = state.copyWith(
        resolvingKey: () => null,
        notice: () => _planNotice(e) ?? _l10n.spotlightNoticeTranslationFailed,
      );
    }
    return null;
  }

  Future<TranslationLookup?> _record(
    String vocabularyId,
    String vocabularyType,
  ) async {
    try {
      final lookup = await ref
          .read(apiClientProvider)
          .lookups
          .record(vocabularyId: vocabularyId, vocabularyType: vocabularyType);
      state = state.copyWith(
        lookups: [
          lookup,
          ...state.lookups.where((existing) => existing.id != lookup.id),
        ],
      );
      return lookup;
    } catch (e, st) {
      appLogger.handle(e, st, 'Spotlight record() error');
      return null;
    }
  }

  void _rebuildItems({bool keepSelection = false}) {
    final library =
        ref.read(cachedUserVocabularyProvider).valueOrNull ?? const [];
    final engine = ref.read(dictionaryManagerProvider).searchEngine;
    final query = state.query.trim();
    final dictionaryWords =
        query.length >= 2 && engine != null && engine.isLoaded
        ? engine.search(query, limit: 8).map((r) => r.word).toList()
        : const <String>[];

    final items = buildSpotlightItems(
      query: query,
      lookups: state.lookups,
      library: library,
      dictionaryWords: dictionaryWords,
    );

    state = state.copyWith(
      items: items,
      selectedIndex: keepSelection
          ? state.selectedIndex.clamp(0, items.isEmpty ? 0 : items.length - 1)
          : 0,
    );
    _scheduleQuickTranslation();
  }

  void _scheduleQuickTranslation() {
    _quickTranslateTimer?.cancel();
    final item = state.selected;
    if (item == null || item.isResolved) return;

    final key = item.term.toLowerCase();
    if (state.quickTranslations.containsKey(key)) return;

    _quickTranslateTimer = Timer(
      const Duration(milliseconds: 200),
      () => _quickTranslate(item.term),
    );
  }

  Future<void> _quickTranslate(String term) async {
    try {
      final available = await ref.read(translationAvailabilityProvider.future);
      if (!available) return;
      final targetLanguage = await ref.read(
        nativeTranslationLanguageProvider.future,
      );

      final result = await ref
          .read(translationServiceProvider)
          .translate(
            text: term,
            sourceLanguage: _sourceLanguage,
            targetLanguage: targetLanguage,
          );
      state = state.copyWith(
        quickTranslations: {
          ...state.quickTranslations,
          term.toLowerCase(): result.translatedText,
        },
      );
    } catch (_) {
      // The on-device preview is best effort; Enter still gets the full
      // translation from the API.
    }
  }
}

final spotlightControllerProvider =
    NotifierProvider<SpotlightController, SpotlightState>(
      SpotlightController.new,
    );
