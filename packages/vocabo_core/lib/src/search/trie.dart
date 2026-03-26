import 'package:vocabo_core/src/search/search_result.dart';

class TrieNode {
  final Map<int, TrieNode> children = {};
  bool isEnd = false;
  int frequency = 0;
}

class Trie {
  final TrieNode _root = TrieNode();
  int _size = 0;

  int get size => _size;

  void insert(String word, int frequency) {
    var node = _root;
    for (var i = 0; i < word.length; i++) {
      final code = word.codeUnitAt(i);
      node = node.children.putIfAbsent(code, TrieNode.new);
    }
    if (!node.isEnd) _size++;
    node.isEnd = true;
    node.frequency = frequency;
  }

  void build(List<({String word, int frequency})> words) {
    for (final w in words) {
      insert(w.word, w.frequency);
    }
  }

  List<SearchResult> prefixSearch(String prefix, {int limit = 10}) {
    var node = _root;
    for (var i = 0; i < prefix.length; i++) {
      final code = prefix.codeUnitAt(i);
      final child = node.children[code];
      if (child == null) return [];
      node = child;
    }

    final results = <SearchResult>[];
    _collectWords(node, prefix, results, limit * 10);

    results.sort((a, b) => b.frequency.compareTo(a.frequency));

    return results.length > limit ? results.sublist(0, limit) : results;
  }

  void _collectWords(
    TrieNode node,
    String currentWord,
    List<SearchResult> results,
    int maxCollect,
  ) {
    if (results.length >= maxCollect) return;

    if (node.isEnd) {
      results.add(SearchResult(
        word: currentWord,
        frequency: node.frequency,
        score: 1.0,
      ));
    }

    node.children.forEach((code, child) {
      if (results.length >= maxCollect) return;
      _collectWords(
        child,
        currentWord + String.fromCharCode(code),
        results,
        maxCollect,
      );
    });
  }
}
