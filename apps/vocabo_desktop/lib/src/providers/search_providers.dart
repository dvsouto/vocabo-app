import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_desktop/src/providers/api_client_provider.dart';
import 'package:vocabo_desktop/src/providers/dictionary_providers.dart';
import 'package:vocabo_desktop/src/services/search_service.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final userWordsEngineProvider = FutureProvider<FuzzySearchEngine?>((ref) async {
  final api = ref.watch(apiClientProvider);

  try {
    final userVocabs = await api.userVocabulary.getAll();
    if (userVocabs.isEmpty) return null;

    final engine = FuzzySearchEngine();
    engine.load(
      userVocabs
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
