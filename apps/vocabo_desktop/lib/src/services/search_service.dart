import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_desktop/src/services/dictionary_manager.dart';

class SearchService {
  final DictionaryManager _dictionaryManager;
  final FuzzySearchEngine? _userWordsEngine;

  SearchService({
    required DictionaryManager dictionaryManager,
    FuzzySearchEngine? userWordsEngine,
  })  : _dictionaryManager = dictionaryManager,
        _userWordsEngine = userWordsEngine;

  List<SearchResult> search(String query, {int limit = 10}) {
    if (query.length < 2) return [];

    final results = <SearchResult>[];

    // Priority 1: User's saved words
    if (_userWordsEngine != null && _userWordsEngine.isLoaded) {
      results.addAll(_userWordsEngine.search(query, limit: limit));
    }

    // Priority 2: General dictionary
    final dictEngine = _dictionaryManager.searchEngine;
    if (dictEngine != null && dictEngine.isLoaded) {
      final dictResults = dictEngine.search(query, limit: limit);
      final existingWords = results.map((r) => r.word.toLowerCase()).toSet();

      for (final r in dictResults) {
        if (results.length >= limit) break;
        if (!existingWords.contains(r.word.toLowerCase())) {
          results.add(r);
        }
      }
    }

    return results.take(limit).toList();
  }
}
