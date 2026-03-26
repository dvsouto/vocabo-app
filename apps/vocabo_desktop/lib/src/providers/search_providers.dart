import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_desktop/src/providers/api_client_provider.dart';
import 'package:vocabo_desktop/src/providers/dictionary_providers.dart';
import 'package:vocabo_desktop/src/services/search_service.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

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
