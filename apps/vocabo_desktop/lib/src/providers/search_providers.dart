import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_desktop/src/providers/api_client_provider.dart';
import 'package:vocabo_desktop/src/providers/dictionary_providers.dart';
import 'package:vocabo_desktop/src/providers/user_vocabulary_providers.dart';
import 'package:vocabo_desktop/src/services/search_service.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

// --- Providers for main engine (API-based) ---

final userWordsEngineProvider = FutureProvider<FuzzySearchEngine?>((ref) async {
  final api = ref.watch(apiClientProvider);

  try {
    final response = await api.userVocabulary.getAll(limit: 100);
    if (response.items.isEmpty) return null;

    final engine = FuzzySearchEngine();
    engine.load(
      response.items
          .where((uv) => uv.vocabulary != null)
          .map((uv) => DictionaryWord(
                word: uv.vocabulary!.term,
                frequency: 1000,
              ))
          .toList(),
    );
    return engine;
  } catch (_) {
    return null;
  }
});

final isTermInVocabularyProvider =
    Provider.family<bool, String>((ref, term) {
  if (term.isEmpty) return false;
  final userEngine = ref.watch(userWordsEngineProvider).valueOrNull;
  if (userEngine == null) return false;
  final results = userEngine.search(term, limit: 1);
  return results.isNotEmpty &&
      results.first.word.toLowerCase() == term.toLowerCase() &&
      results.first.score >= 1.0;
});

final searchServiceProvider = Provider<SearchService>((ref) {
  final dictManager = ref.watch(dictionaryManagerProvider);
  final userEngine = ref.watch(userWordsEngineProvider).valueOrNull;
  return SearchService(
    dictionaryManager: dictManager,
    userWordsEngine: userEngine,
  );
});

final searchResultsProvider = Provider<List<SearchResult>>((ref) {
  final query = ref.watch(searchQueryProvider);
  if (query.length < 2) return [];
  final service = ref.watch(searchServiceProvider);
  return service.search(query);
});

// --- Providers for tray engine (local cache-based) ---

final localUserWordsEngineProvider =
    FutureProvider<FuzzySearchEngine?>((ref) async {
  final cached = await ref.watch(cachedUserVocabularyProvider.future);
  if (cached.isEmpty) return null;

  final engine = FuzzySearchEngine();
  engine.load(
    cached
        .where((uv) => uv.vocabulary != null)
        .map((uv) => DictionaryWord(
              word: uv.vocabulary!.term,
              frequency: 1000,
            ))
        .toList(),
  );
  return engine;
});

final localIsTermInVocabularyProvider =
    Provider.family<bool, String>((ref, term) {
  if (term.isEmpty) return false;
  final userEngine = ref.watch(localUserWordsEngineProvider).valueOrNull;
  if (userEngine == null) return false;
  final results = userEngine.search(term, limit: 1);
  return results.isNotEmpty &&
      results.first.word.toLowerCase() == term.toLowerCase() &&
      results.first.score >= 1.0;
});

final localSearchServiceProvider = Provider<SearchService>((ref) {
  final dictManager = ref.watch(dictionaryManagerProvider);
  final userEngine = ref.watch(localUserWordsEngineProvider).valueOrNull;
  return SearchService(
    dictionaryManager: dictManager,
    userWordsEngine: userEngine,
  );
});

final localSearchResultsProvider = Provider<List<SearchResult>>((ref) {
  final query = ref.watch(searchQueryProvider);
  if (query.length < 2) return [];
  final service = ref.watch(localSearchServiceProvider);
  return service.search(query);
});

final recentCachedVocabularyProvider =
    Provider.family<AsyncValue<List<UserVocabulary>>, String>(
        (ref, query) {
  return ref.watch(cachedUserVocabularyProvider).whenData((items) {
    final withVocabulary =
        items.where((uv) => uv.vocabulary != null).toList();

    if (query.isEmpty) {
      return withVocabulary.take(5).toList();
    }

    final lowerQuery = query.toLowerCase();
    return withVocabulary
        .where((uv) =>
            uv.vocabulary!.term.toLowerCase().contains(lowerQuery))
        .take(5)
        .toList();
  });
});
