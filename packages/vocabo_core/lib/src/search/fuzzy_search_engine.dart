import 'package:vocabo_core/src/models/dictionary_word.dart';
import 'package:vocabo_core/src/search/levenshtein.dart';
import 'package:vocabo_core/src/search/search_result.dart';
import 'package:vocabo_core/src/search/trie.dart';

class FuzzySearchEngine {
  final Trie _trie = Trie();
  List<DictionaryWord> _words = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;
  int get wordCount => _trie.size;

  void load(List<DictionaryWord> words) {
    _words = words;
    for (final w in words) {
      _trie.insert(w.word.toLowerCase(), w.frequency);
    }
    _loaded = true;
  }

  List<SearchResult> search(
    String query, {
    int limit = 10,
    int maxDistance = 2,
  }) {
    if (!_loaded || query.length < 2) return [];

    final normalizedQuery = query.toLowerCase();

    // Phase 1: Prefix matching via Trie (fastest, highest relevance)
    final prefixResults = _trie.prefixSearch(normalizedQuery, limit: limit);

    if (prefixResults.length >= limit) {
      return prefixResults;
    }

    // Phase 2: Fuzzy matching via Levenshtein (fallback)
    final existingWords = <String>{
      for (final r in prefixResults) r.word,
    };

    final fuzzyResults = <SearchResult>[];
    final queryLen = normalizedQuery.length;

    for (final w in _words) {
      final word = w.word.toLowerCase();

      // Early length filter: skip words too different in length
      if ((word.length - queryLen).abs() > maxDistance) continue;

      // Skip already found in prefix results
      if (existingWords.contains(word)) continue;

      final distance = levenshteinDistance(normalizedQuery, word);
      if (distance <= maxDistance && distance > 0) {
        final similarity = normalizedSimilarity(normalizedQuery, word);
        fuzzyResults.add(SearchResult(
          word: word,
          frequency: w.frequency,
          score: similarity * 0.8, // Fuzzy results score lower than prefix
        ));
      }
    }

    // Sort fuzzy by combined score (similarity * frequency weight)
    fuzzyResults.sort((a, b) {
      final scoreA = a.score * (1 + a.frequency / 1000000);
      final scoreB = b.score * (1 + b.frequency / 1000000);
      return scoreB.compareTo(scoreA);
    });

    // Merge: prefix first, then fuzzy
    final merged = [...prefixResults];
    for (final r in fuzzyResults) {
      if (merged.length >= limit) break;
      merged.add(r);
    }

    return merged;
  }
}
